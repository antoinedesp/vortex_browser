#import "ios/chrome/browser/vortex_vpn/vortex_vpn_manager.h"
#import <NetworkExtension/NetworkExtension.h>
#import "ios/third_party/vortex/src/vortex_constants.h"

@interface VortexVPNManager ()
@property(nonatomic, assign, readwrite) VortexVPNStatus status;
@property(nonatomic, strong) NSHashTable<id<VortexVPNObserver>>* observers;
@property(nonatomic, strong) NEVPNManager* vpnManager;
@property(nonatomic, assign) BOOL connectionInProgress;
@end

@implementation VortexVPNManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
  static VortexVPNManager* instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[VortexVPNManager alloc] initPrivate];
  });
  return instance;
}

- (instancetype)init {
  NSAssert(NO, @"Use +sharedManager");
  return [self initPrivate];
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _status = VortexVPNStatusDisconnected;
    _observers = [NSHashTable weakObjectsHashTable];
    _vpnManager = [NEVPNManager sharedManager];
    _connectionInProgress = NO;

    [self loadVPNConfiguration];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(vpnStatusDidChange:)
               name:NEVPNStatusDidChangeNotification
             object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Configuration

- (void)loadVPNConfiguration {
  __weak __typeof__(self) weakSelf = self;
  [self.vpnManager loadFromPreferencesWithCompletionHandler:^(NSError* error) {
    if (error) {
      weakSelf.status = VortexVPNStatusDisconnected;
      [weakSelf notifyObservers];
      return;
    }
    [weakSelf updateStatusFromNEVPNStatus];
  }];
}

- (BOOL)isConfigured {
  return self.vpnManager.protocolConfiguration != nil;
}

#pragma mark - Status Updates

- (void)vpnStatusDidChange:(NSNotification*)notification {
  [self updateStatusFromNEVPNStatus];
}

- (void)updateStatusFromNEVPNStatus {
  NEVPNStatus vpnStatus = self.vpnManager.connection.status;

  VortexVPNStatus newStatus;
  switch (vpnStatus) {
    case NEVPNStatusInvalid:
    case NEVPNStatusDisconnected:
      newStatus = VortexVPNStatusDisconnected;
      break;
    case NEVPNStatusConnecting:
    case NEVPNStatusReasserting:
    case NEVPNStatusDisconnecting:
      newStatus = VortexVPNStatusConnecting;
      break;
    case NEVPNStatusConnected:
      newStatus = VortexVPNStatusConnected;
      break;
  }

  // Reset connectionInProgress flag when we reach a terminal state
  if (newStatus == VortexVPNStatusConnected || newStatus == VortexVPNStatusDisconnected) {
    @synchronized(self) {
      self.connectionInProgress = NO;
    }
  }

  if (self.status != newStatus) {
    self.status = newStatus;
    [self notifyObservers];
  }
}

#pragma mark - Public API

- (void)toggle {
  if (self.status == VortexVPNStatusConnected ||
      self.status == VortexVPNStatusConnecting) {
    [self disconnect];
  } else {
    [self connect];
  }
}

- (void)connect {
  @synchronized(self) {
    if (self.connectionInProgress ||
        self.status == VortexVPNStatusConnected ||
        self.status == VortexVPNStatusConnecting) {
      return;
    }
    self.connectionInProgress = YES;
  }

  self.status = VortexVPNStatusConnecting;
  [self notifyObservers];

  __weak __typeof__(self) weakSelf = self;
  [self fetchRandomServerWithCompletion:^(NSString* serverAddress,
                                          NSString* sharedSecret,
                                          NSString* username,
                                          NSString* password,
                                          NSError* error) {
    __strong __typeof__(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;

    if (error || serverAddress.length == 0 || sharedSecret.length == 0) {
      [strongSelf handleConnectionError];
      return;
    }

    [strongSelf configureWithServer:serverAddress
                       sharedSecret:sharedSecret
                           username:username
                           password:password
                  completionHandler:^(BOOL success, NSError* configError) {
      if (!success || configError) {
        [strongSelf handleConnectionError];
        return;
      }

      NEVPNStatus currentStatus = strongSelf.vpnManager.connection.status;
      if (currentStatus == NEVPNStatusConnecting || currentStatus == NEVPNStatusConnected) {
        return; // Already connecting/connected by system
      }

      NSError* startError = nil;
      BOOL started = [strongSelf.vpnManager.connection startVPNTunnelAndReturnError:&startError];

      if (!started || startError) {
        [strongSelf handleConnectionError];
      }
    }];
  }];
}

- (void)disconnect {
  if (self.status == VortexVPNStatusDisconnected) {
    return;
  }
  [self.vpnManager.connection stopVPNTunnel];
}

- (void)handleConnectionError {
  @synchronized(self) {
    self.connectionInProgress = NO;
  }
  self.status = VortexVPNStatusError;
  [self notifyObservers];
}

#pragma mark - Server Fetch

- (void)fetchRandomServerWithCompletion:(void (^)(NSString* _Nullable serverAddress,
                                                  NSString* _Nullable sharedSecret,
                                                  NSString* _Nullable username,
                                                  NSString* _Nullable password,
                                                  NSError* _Nullable error))completion {
  NSURL* url = [NSURL URLWithString:VORTEX_RANDOM_SERVER_ENDPOINT_URL];
  if (!url) {
    if (completion) {
      NSError* err = [NSError errorWithDomain:@"VortexVPN"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
      completion(nil, nil, nil, nil, err);
    }
    return;
  }

  NSURLSessionDataTask* task =
      [[NSURLSession sharedSession]
          dataTaskWithURL:url
        completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
          if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion) completion(nil, nil, nil, nil, error);
            });
            return;
          }

          NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
          if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]] ||
              httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
            NSError* statusError = [NSError errorWithDomain:@"VortexVPN"
                                                       code:1002
                                                   userInfo:@{NSLocalizedDescriptionKey: @"Server error"}];
            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion) completion(nil, nil, nil, nil, statusError);
            });
            return;
          }

          if (!data) {
            NSError* dataError = [NSError errorWithDomain:@"VortexVPN"
                                                     code:1003
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Empty response"}];
            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion) completion(nil, nil, nil, nil, dataError);
            });
            return;
          }

          NSError* jsonError = nil;
          NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
          if (jsonError || ![dict isKindOfClass:[NSDictionary class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion) completion(nil, nil, nil, nil, jsonError);
            });
            return;
          }

          NSString* ip = dict[@"ip"];
          NSString* psk = dict[@"psk"];
          NSString* username = dict[@"username"];
          NSString* password = dict[@"password"];
          NSNumber* isOnline = dict[@"is_online"];

          if (![ip isKindOfClass:[NSString class]] || ![psk isKindOfClass:[NSString class]]) {
            NSError* fieldError = [NSError errorWithDomain:@"VortexVPN"
                                                      code:1004
                                                  userInfo:@{NSLocalizedDescriptionKey: @"Invalid server data"}];
            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion) completion(nil, nil, nil, nil, fieldError);
            });
            return;
          }

          if ([isOnline respondsToSelector:@selector(boolValue)] && !isOnline.boolValue) {
            NSError* offlineError = [NSError errorWithDomain:@"VortexVPN"
                                                        code:1005
                                                    userInfo:@{NSLocalizedDescriptionKey: @"Server offline"}];
            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion) completion(nil, nil, nil, nil, offlineError);
            });
            return;
          }

          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(ip, psk, username, password, nil);
          });
        }];

  [task resume];
}

#pragma mark - VPN Configuration

- (void)configureWithServer:(NSString*)serverAddress
               sharedSecret:(NSString*)sharedSecret
                   username:(NSString*)username
                   password:(NSString*)password
          completionHandler:(void (^)(BOOL success, NSError* _Nullable error))completion {

  if (serverAddress.length == 0 || sharedSecret.length == 0 ||
      username.length == 0 || password.length == 0) {
    if (completion) {
      NSError* error = [NSError errorWithDomain:@"VortexVPN"
                                           code:2000
                                       userInfo:@{NSLocalizedDescriptionKey: @"Missing credentials"}];
      completion(NO, error);
    }
    return;
  }

  NSData* sharedSecretRef = [self saveToKeychain:sharedSecret forKey:@"SharedSecret"];
  NSData* passwordRef = [self saveToKeychain:password forKey:@"Password"];

  if (!sharedSecretRef || !passwordRef) {
    if (completion) {
      NSError* error = [NSError errorWithDomain:@"VortexVPN"
                                           code:2001
                                       userInfo:@{NSLocalizedDescriptionKey: @"Keychain error"}];
      completion(NO, error);
    }
    return;
  }

  // Configure IPSec/XAuth for hwdsl2/ipsec-vpn-server
  NEVPNProtocolIPSec* protocol = [[NEVPNProtocolIPSec alloc] init];
  protocol.serverAddress = serverAddress;
  protocol.remoteIdentifier = serverAddress;
  protocol.localIdentifier = nil;  // Empty group name for hwdsl2 default
  protocol.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
  protocol.sharedSecretReference = sharedSecretRef;
  protocol.useExtendedAuthentication = YES;
  protocol.username = username;
  protocol.passwordReference = passwordRef;
  protocol.disconnectOnSleep = NO;

  self.vpnManager.protocolConfiguration = protocol;
  self.vpnManager.localizedDescription = @"Vortex VPN";
  self.vpnManager.enabled = YES;

  __weak __typeof__(self) weakSelf = self;
  [self.vpnManager saveToPreferencesWithCompletionHandler:^(NSError* error) {
    if (error) {
      if (completion) completion(NO, error);
      return;
    }

    [weakSelf.vpnManager loadFromPreferencesWithCompletionHandler:^(NSError* loadError) {
      if (loadError) {
        if (completion) completion(NO, loadError);
        return;
      }

      [weakSelf updateStatusFromNEVPNStatus];
      if (completion) completion(YES, nil);
    }];
  }];
}

#pragma mark - Keychain

- (NSData*)saveToKeychain:(NSString*)value forKey:(NSString*)key {
  NSData* valueData = [value dataUsingEncoding:NSUTF8StringEncoding];

  NSDictionary* deleteQuery = @{
    (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
    (__bridge id)kSecAttrService: @"VortexVPN",
    (__bridge id)kSecAttrAccount: key,
  };
  SecItemDelete((__bridge CFDictionaryRef)deleteQuery);

  NSDictionary* addQuery = @{
    (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
    (__bridge id)kSecAttrService: @"VortexVPN",
    (__bridge id)kSecAttrAccount: key,
    (__bridge id)kSecValueData: valueData,
    (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
    (__bridge id)kSecReturnPersistentRef: @YES,
  };

  CFTypeRef result = NULL;
  OSStatus status = SecItemAdd((__bridge CFDictionaryRef)addQuery, &result);

  if (status != errSecSuccess) {
    return nil;
  }

  return (__bridge_transfer NSData*)result;
}

#pragma mark - Observers

- (void)addObserver:(id<VortexVPNObserver>)observer {
  if (!observer) return;

  @synchronized(self) {
    [self.observers addObject:observer];
  }
  [observer vpnManagerDidUpdateStatus:self.status];
}

- (void)removeObserver:(id<VortexVPNObserver>)observer {
  if (!observer) return;

  @synchronized(self) {
    [self.observers removeObject:observer];
  }
}

- (void)notifyObservers {
  NSArray* snapshot;
  @synchronized(self) {
    snapshot = self.observers.allObjects;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    for (id<VortexVPNObserver> observer in snapshot) {
      [observer vpnManagerDidUpdateStatus:self.status];
    }
  });
}

@end