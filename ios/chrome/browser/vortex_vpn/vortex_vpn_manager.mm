#import "ios/chrome/browser/vortex_vpn/vortex_vpn_manager.h"
#import <NetworkExtension/NetworkExtension.h>

@interface VortexVPNManager ()
@property(nonatomic, assign, readwrite) VortexVPNStatus status;
@property(nonatomic, strong) NSHashTable<id<VortexVPNObserver>>* observers;
@property(nonatomic, strong) NEVPNManager* vpnManager;
@end

@implementation VortexVPNManager

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

    // Load existing configuration
    [self loadVPNConfiguration];

    // Listen to VPN status changes
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
      NSLog(@"🔴 [VortexVPNManager] Failed to load VPN config: %@", error);
      return;
    }

    NSLog(@"🟢 [VortexVPNManager] VPN configuration loaded");
    [weakSelf updateStatusFromNEVPNStatus];
  }];
}

// Legacy static configuration (kept for compatibility / fallback, no longer
// used by -connect).
- (void)configureVPNIfNeeded {
  // Only configure if not already configured
  if (self.vpnManager.protocolConfiguration != nil) {
    NSLog(@"🔵 [VortexVPNManager] VPN already configured");
    return;
  }

  NSLog(@"🔵 [VortexVPNManager] Configuring VPN for first time (static config)");

  NEVPNProtocolIKEv2* ikev2 = [[NEVPNProtocolIKEv2 alloc] init];

  ikev2.serverAddress = @"vpn.vortex.com";
  ikev2.remoteIdentifier = @"vpn.vortex.com";
  ikev2.localIdentifier = @"vortex-user";

  ikev2.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
  ikev2.sharedSecretReference = [self saveSharedSecretToKeychain:@"your-shared-secret"];

  ikev2.useExtendedAuthentication = YES;
  ikev2.disconnectOnSleep = NO;
  ikev2.deadPeerDetectionRate = NEVPNIKEv2DeadPeerDetectionRateMedium;

  self.vpnManager.protocolConfiguration = ikev2;
  self.vpnManager.localizedDescription = @"Vortex VPN";
  self.vpnManager.enabled = YES;

  NEOnDemandRuleConnect* connectRule = [[NEOnDemandRuleConnect alloc] init];
  self.vpnManager.onDemandRules = @[connectRule];
  self.vpnManager.onDemandEnabled = NO;

  __weak __typeof__(self) weakSelf = self;
  [self.vpnManager saveToPreferencesWithCompletionHandler:^(NSError* error) {
    if (error) {
      NSLog(@"🔴 [VortexVPNManager] Failed to save VPN config: %@", error);
      weakSelf.status = VortexVPNStatusError;
      [weakSelf notifyObservers];
      return;
    }

    NSLog(@"🟢 [VortexVPNManager] VPN configuration saved");
    [weakSelf loadVPNConfiguration];
  }];
}

#pragma mark - Status Updates

- (void)vpnStatusDidChange:(NSNotification*)notification {
  NSLog(@"🔵 [VortexVPNManager] VPN status changed");
  [self updateStatusFromNEVPNStatus];
}

- (void)updateStatusFromNEVPNStatus {
  NEVPNStatus vpnStatus = self.vpnManager.connection.status;

  VortexVPNStatus newStatus;
  switch (vpnStatus) {
    case NEVPNStatusInvalid:
      newStatus = VortexVPNStatusError;
      NSLog(@"🔴 [VortexVPNManager] Status: Invalid");
      break;
    case NEVPNStatusDisconnected:
      newStatus = VortexVPNStatusDisconnected;
      NSLog(@"⚪️ [VortexVPNManager] Status: Disconnected");
      break;
    case NEVPNStatusConnecting:
      newStatus = VortexVPNStatusConnecting;
      NSLog(@"🟡 [VortexVPNManager] Status: Connecting");
      break;
    case NEVPNStatusConnected:
      newStatus = VortexVPNStatusConnected;
      NSLog(@"🟢 [VortexVPNManager] Status: Connected");
      break;
    case NEVPNStatusReasserting:
      newStatus = VortexVPNStatusConnecting;
      NSLog(@"🟡 [VortexVPNManager] Status: Reasserting");
      break;
    case NEVPNStatusDisconnecting:
      newStatus = VortexVPNStatusConnecting;
      NSLog(@"🟡 [VortexVPNManager] Status: Disconnecting");
      break;
  }

  if (self.status != newStatus) {
    self.status = newStatus;
    [self notifyObservers];
  }
}

#pragma mark - Random server fetch

/// Fetches a random server configuration from the Vortex backend.
///
/// GET https://vortexbrowser.com/api/random-server
/// Expected JSON fields: uuid, ip, port, username, password, is_online,
/// is_premium, country, psk, flag
- (void)fetchRandomServerWithCompletion:(void (^)(NSString* _Nullable serverAddress,
                                                  NSString* _Nullable sharedSecret,
                                                  NSError* _Nullable error))completion {
  NSURL* url = [NSURL URLWithString:@"https://vortexbrowser.com/api/random-server"];
  if (!url) {
    if (completion) {
      NSError* err = [NSError errorWithDomain:@"VortexVPN"
                                         code:1001
                                     userInfo:@{
                                       NSLocalizedDescriptionKey :
                                           @"Invalid random-server URL"
                                     }];
      completion(nil, nil, err);
    }
    return;
  }

  NSLog(@"🔵 [VortexVPNManager] Fetching random VPN server…");

  NSURLSessionDataTask* task =
      [[NSURLSession sharedSession]
          dataTaskWithURL:url
        completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
          if (error) {
            NSLog(@"🔴 [VortexVPNManager] Random server request failed: %@", error);
            if (completion) {
              dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil, error);
              });
            }
            return;
          }

          NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
          if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]] ||
              httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
            NSString* msg = [NSString
                stringWithFormat:@"Unexpected status code: %ld",
                                 (long)httpResponse.statusCode];
            NSLog(@"🔴 [VortexVPNManager] %@", msg);
            if (completion) {
              NSError* statusError =
                  [NSError errorWithDomain:@"VortexVPN"
                                      code:1002
                                  userInfo:@{NSLocalizedDescriptionKey : msg}];
              dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil, statusError);
              });
            }
            return;
          }

          if (!data) {
            NSString* msg = @"Empty response body from random-server";
            NSLog(@"🔴 [VortexVPNManager] %@", msg);
            if (completion) {
              NSError* dataError =
                  [NSError errorWithDomain:@"VortexVPN"
                                      code:1003
                                  userInfo:@{NSLocalizedDescriptionKey : msg}];
              dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil, dataError);
              });
            }
            return;
          }

          NSError* jsonError = nil;
          id json = [NSJSONSerialization JSONObjectWithData:data
                                                    options:0
                                                      error:&jsonError];
          if (jsonError || ![json isKindOfClass:[NSDictionary class]]) {
            NSLog(@"🔴 [VortexVPNManager] JSON parse error: %@", jsonError);
            if (completion) {
              dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil, jsonError);
              });
            }
            return;
          }

          NSDictionary* dict = (NSDictionary*)json;
          NSString* ip = dict[@"ip"];
          NSString* psk = dict[@"psk"];
          NSNumber* isOnline = dict[@"is_online"];
          id portValue = dict[@"port"];
          NSString* port =
              portValue ? [NSString stringWithFormat:@"%@", portValue] : nil;

          if (![ip isKindOfClass:[NSString class]] ||
              ![psk isKindOfClass:[NSString class]]) {
            NSString* msg = @"Missing or invalid ip/psk in random-server JSON";
            NSLog(@"🔴 [VortexVPNManager] %@", msg);
            if (completion) {
              NSError* fieldError =
                  [NSError errorWithDomain:@"VortexVPN"
                                      code:1004
                                  userInfo:@{NSLocalizedDescriptionKey : msg}];
              dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil, fieldError);
              });
            }
            return;
          }

          if ([isOnline respondsToSelector:@selector(boolValue)] &&
              !isOnline.boolValue) {
            NSString* msg = @"Random-server returned an offline server";
            NSLog(@"🔴 [VortexVPNManager] %@", msg);
            if (completion) {
              NSError* offlineError =
                  [NSError errorWithDomain:@"VortexVPN"
                                      code:1005
                                  userInfo:@{NSLocalizedDescriptionKey : msg}];
              dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil, offlineError);
              });
            }
            return;
          }

          // For IKEv2 we typically just use host/IP. If you want to include a
          // non-standard port, you can append `:port` here:
          NSString* serverAddress = ip;
          if (port.length > 0) {
            // Uncomment if your gateway expects host:port
            // serverAddress = [NSString stringWithFormat:@"%@:%@", ip, port];
            NSLog(@"🔵 [VortexVPNManager] Selected server %@:%@", ip, port);
          } else {
            NSLog(@"🔵 [VortexVPNManager] Selected server %@", ip);
          }

          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
              completion(serverAddress, psk, nil);
            }
          });
        }];

  [task resume];
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
  if (self.status == VortexVPNStatusConnected ||
      self.status == VortexVPNStatusConnecting) {
    NSLog(@"🟡 [VortexVPNManager] Already connected or connecting");
    return;
  }

  NSLog(@"🔵 [VortexVPNManager] Connect requested");
  self.status = VortexVPNStatusConnecting;
  [self notifyObservers];

  __weak __typeof__(self) weakSelf = self;
  [self fetchRandomServerWithCompletion:^(NSString* serverAddress,
                                          NSString* sharedSecret,
                                          NSError* error) {
    __strong __typeof__(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    if (error || serverAddress.length == 0 || sharedSecret.length == 0) {
      NSLog(@"🔴 [VortexVPNManager] Failed to fetch VPN server: %@", error);
      strongSelf.status = VortexVPNStatusError;
      [strongSelf notifyObservers];
      return;
    }

    NSLog(@"🔵 [VortexVPNManager] Configuring VPN for server: %@", serverAddress);

    [strongSelf configureWithServer:serverAddress
                        sharedSecret:sharedSecret
                  completionHandler:^(BOOL success, NSError* configError) {
      if (!success || configError) {
        NSLog(@"🔴 [VortexVPNManager] Failed to configure VPN: %@", configError);
        strongSelf.status = VortexVPNStatusError;
        [strongSelf notifyObservers];
        return;
      }

      NSError* startError = nil;
      BOOL started =
          [strongSelf.vpnManager.connection startVPNTunnelAndReturnError:&startError];
      if (!started || startError) {
        NSLog(@"🔴 [VortexVPNManager] Failed to start VPN: %@", startError);
        strongSelf.status = VortexVPNStatusError;
        [strongSelf notifyObservers];
        return;
      }

      NSLog(@"🟢 [VortexVPNManager] VPN connection initiated");
      // Actual status changes will come via NEVPNStatusDidChangeNotification.
    }];
  }];
}

- (void)disconnect {
  if (self.status == VortexVPNStatusDisconnected) {
    NSLog(@"⚪️ [VortexVPNManager] Already disconnected");
    return;
  }

  NSLog(@"🔵 [VortexVPNManager] Disconnect requested");
  [self.vpnManager.connection stopVPNTunnel];

  // Status will be updated via NEVPNStatusDidChangeNotification
}

#pragma mark - Observers

- (void)addObserver:(id<VortexVPNObserver>)observer {
  if (!observer) {
    return;
  }
  @synchronized(self) {
    [self.observers addObject:observer];
  }

  // Immediately notify new observer of current status
  [observer vpnManagerDidUpdateStatus:self.status];
}

- (void)removeObserver:(id<VortexVPNObserver>)observer {
  if (!observer) {
    return;
  }
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

#pragma mark - Keychain Helpers

- (NSData*)saveSharedSecretToKeychain:(NSString*)secret {
  NSData* secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];

  NSDictionary* deleteQuery = @{
    (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
    (__bridge id)kSecAttrService: @"VortexVPN",
    (__bridge id)kSecAttrAccount: @"SharedSecret",
  };
  SecItemDelete((__bridge CFDictionaryRef)deleteQuery);

  NSDictionary* addQuery = @{
    (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
    (__bridge id)kSecAttrService: @"VortexVPN",
    (__bridge id)kSecAttrAccount: @"SharedSecret",
    (__bridge id)kSecValueData: secretData,
    (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
    (__bridge id)kSecReturnPersistentRef: @YES,
  };

  CFTypeRef result = NULL;
  OSStatus status = SecItemAdd((__bridge CFDictionaryRef)addQuery, &result);

  if (status != errSecSuccess) {
    NSLog(@"🔴 [VortexVPNManager] Failed to save shared secret: %d", (int)status);
    return nil;
  }

  NSLog(@"🟢 [VortexVPNManager] Shared secret saved to keychain");
  return (__bridge_transfer NSData*)result;
}

- (BOOL)isConfigured {
  return self.vpnManager.protocolConfiguration != nil;
}

// Public configuration helper (kept for compatibility, now reused internally).
- (void)configureWithServer:(NSString*)serverAddress
               sharedSecret:(NSString*)sharedSecret
          completionHandler:(void (^)(BOOL success, NSError* _Nullable error))completion {
  NSLog(@"🔵 [VortexVPNManager] Configuring VPN with server: %@", serverAddress);

  NEVPNProtocolIKEv2* ikev2 = [[NEVPNProtocolIKEv2 alloc] init];
  ikev2.serverAddress = serverAddress;
  ikev2.remoteIdentifier = serverAddress;
  ikev2.localIdentifier = @"vortex-user";
  ikev2.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
  ikev2.sharedSecretReference = [self saveSharedSecretToKeychain:sharedSecret];
  ikev2.useExtendedAuthentication = YES;
  ikev2.disconnectOnSleep = NO;
  ikev2.deadPeerDetectionRate = NEVPNIKEv2DeadPeerDetectionRateMedium;

  self.vpnManager.protocolConfiguration = ikev2;
  self.vpnManager.localizedDescription = @"Vortex VPN";
  self.vpnManager.enabled = YES;

  __weak __typeof__(self) weakSelf = self;
  [self.vpnManager saveToPreferencesWithCompletionHandler:^(NSError* error) {
    if (error) {
      NSLog(@"🔴 [VortexVPNManager] Failed to save configuration: %@", error);
      if (completion) {
        completion(NO, error);
      }
      return;
    }

    NSLog(@"🟢 [VortexVPNManager] Configuration saved successfully");
    [weakSelf loadVPNConfiguration];

    if (completion) {
      completion(YES, nil);
    }
  }];
}

@end