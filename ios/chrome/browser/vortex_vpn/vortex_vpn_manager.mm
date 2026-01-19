#import "ios/chrome/browser/vortex_vpn/vortex_vpn_manager.h"
#import <NetworkExtension/NetworkExtension.h>
#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_server.h"
#import "ios/third_party/vortex/src/vortex_constants.h"

// Tunnel provider bundle identifier - must match the VPN extension's bundle ID
static NSString* const kTunnelProviderBundleIdentifier = @"com.vortexbrowser.app.VPN";

@interface VortexVPNManager ()
@property(nonatomic, assign, readwrite) VortexVPNStatus status;
@property(nonatomic, strong) NSHashTable<id<VortexVPNObserver>>* observers;
@property(nonatomic, strong) NEVPNManager* vpnManager;  // For IPSec
@property(nonatomic, strong) NETunnelProviderManager* tunnelManager;  // For OpenVPN
@property(nonatomic, assign) BOOL connectionInProgress;
@property(nonatomic, strong, nullable, readwrite) VortexVPNServer* selectedServer;
@property(nonatomic, assign) BOOL usingOpenVPN;  // Track which protocol is active
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
    _usingOpenVPN = NO;

    [self loadVPNConfiguration];
    [self loadTunnelProviderConfiguration];

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
      NSLog(@"[VortexVPNManager] Failed to load IPSec config: %@", error);
      return;
    }
    NSLog(@"[VortexVPNManager] IPSec configuration loaded");
    [weakSelf updateStatusFromNEVPNStatus];
  }];
}

- (void)loadTunnelProviderConfiguration {
  __weak __typeof__(self) weakSelf = self;
  [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(
      NSArray<NETunnelProviderManager*>* _Nullable managers, NSError* _Nullable error) {
    if (error) {
      NSLog(@"[VortexVPNManager] Failed to load tunnel configs: %@", error);
      return;
    }

    // Find our tunnel provider manager
    for (NETunnelProviderManager* manager in managers) {
      NETunnelProviderProtocol* proto =
          (NETunnelProviderProtocol*)manager.protocolConfiguration;
      if ([proto.providerBundleIdentifier isEqualToString:kTunnelProviderBundleIdentifier]) {
        weakSelf.tunnelManager = manager;
        NSLog(@"[VortexVPNManager] Found existing OpenVPN tunnel configuration");
        break;
      }
    }

    if (!weakSelf.tunnelManager) {
      NSLog(@"[VortexVPNManager] No existing OpenVPN tunnel configuration found");
    }

    [weakSelf updateStatusFromNEVPNStatus];
  }];
}

- (BOOL)isConfigured {
  return self.vpnManager.protocolConfiguration != nil ||
         self.tunnelManager.protocolConfiguration != nil;
}

- (BOOL)isConnected {
  return self.status == VortexVPNStatusConnected;
}

#pragma mark - Status Updates

- (void)vpnStatusDidChange:(NSNotification*)notification {
  [self updateStatusFromNEVPNStatus];
}

- (void)updateStatusFromNEVPNStatus {
  // Get status from the active manager based on which protocol is in use
  NEVPNStatus vpnStatus;
  if (self.usingOpenVPN && self.tunnelManager) {
    vpnStatus = self.tunnelManager.connection.status;
  } else {
    vpnStatus = self.vpnManager.connection.status;
  }

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

  // If a server is selected, use it directly; otherwise fetch a random server.
  NSLog(@"[VortexVPNManager] connect called, selectedServer: %@", self.selectedServer);
  if (self.selectedServer) {
    NSLog(@"[VortexVPNManager] Using selected server: %@", self.selectedServer.ip);
    [self connectToServer:self.selectedServer];
  } else {
    NSLog(@"[VortexVPNManager] No selected server, fetching random...");
    __weak __typeof__(self) weakSelf = self;
    [self fetchRandomServerWithCompletion:^(VortexVPNServer* server, NSError* error) {
      __strong __typeof__(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) return;

      if (error || !server) {
        [strongSelf handleConnectionError];
        return;
      }

      // Use connectToServer which handles both OpenVPN and IPSec
      [strongSelf connectToServer:server];
    }];
  }
}

- (void)connectToServer:(VortexVPNServer*)server {
  NSLog(@"[VortexVPNManager] Connecting to server: %@ (%@)", server.ip,
        [server countryDisplayName]);
  NSLog(@"[VortexVPNManager] Server has ovpnConfig: %@, psk: %@",
        server.ovpnConfig ? @"YES" : @"NO",
        server.psk ? @"YES" : @"NO");

  // Prefer OpenVPN if available
  if (server.ovpnConfig && server.ovpnConfig.length > 0) {
    NSLog(@"[VortexVPNManager] Using OpenVPN protocol");
    self.usingOpenVPN = YES;
    [self connectWithOpenVPNConfig:server.ovpnConfig
                          username:server.username
                          password:server.password];
  } else if (server.psk && server.psk.length > 0) {
    NSLog(@"[VortexVPNManager] Using IPSec protocol");
    self.usingOpenVPN = NO;
    [self connectWithServerAddress:server.ip
                      sharedSecret:server.psk
                          username:server.username
                          password:server.password];
  } else {
    NSLog(@"[VortexVPNManager] Server has no valid configuration");
    [self handleConnectionError];
  }
}

- (void)connectWithServerAddress:(NSString*)serverAddress
                    sharedSecret:(NSString*)sharedSecret
                        username:(NSString*)username
                        password:(NSString*)password {
  __weak __typeof__(self) weakSelf = self;
  [self configureWithServer:serverAddress
               sharedSecret:sharedSecret
                   username:username
                   password:password
          completionHandler:^(BOOL success, NSError* configError) {
    __strong __typeof__(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;

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
}

#pragma mark - OpenVPN Connection

- (void)connectWithOpenVPNConfig:(NSString*)ovpnConfig
                        username:(NSString* _Nullable)username
                        password:(NSString* _Nullable)password {
  NSLog(@"[VortexVPNManager] Configuring OpenVPN connection");

  __weak __typeof__(self) weakSelf = self;

  // Create or update tunnel provider manager
  void (^configureAndConnect)(NETunnelProviderManager*) = ^(NETunnelProviderManager* manager) {
    NETunnelProviderProtocol* proto = [[NETunnelProviderProtocol alloc] init];
    proto.providerBundleIdentifier = kTunnelProviderBundleIdentifier;
    proto.serverAddress = @"Vortex VPN";  // Display name

    // Store OpenVPN config in providerConfiguration
    NSMutableDictionary* providerConfig = [NSMutableDictionary dictionary];
    providerConfig[@"ovpn_config"] = ovpnConfig;
    if (username) {
      providerConfig[@"username"] = username;
    }
    if (password) {
      providerConfig[@"password"] = password;
    }
    proto.providerConfiguration = providerConfig;

    manager.protocolConfiguration = proto;
    manager.localizedDescription = @"Vortex VPN";
    manager.enabled = YES;

    [manager saveToPreferencesWithCompletionHandler:^(NSError* saveError) {
      if (saveError) {
        NSLog(@"[VortexVPNManager] Failed to save OpenVPN config: %@", saveError);
        [weakSelf handleConnectionError];
        return;
      }

      NSLog(@"[VortexVPNManager] OpenVPN config saved, loading...");

      // Reload to ensure configuration is properly loaded
      [manager loadFromPreferencesWithCompletionHandler:^(NSError* loadError) {
        if (loadError) {
          NSLog(@"[VortexVPNManager] Failed to reload config: %@", loadError);
          [weakSelf handleConnectionError];
          return;
        }

        weakSelf.tunnelManager = manager;

        // Start the tunnel
        NSError* startError = nil;
        BOOL started = [manager.connection startVPNTunnelAndReturnError:&startError];
        if (!started || startError) {
          NSLog(@"[VortexVPNManager] Failed to start OpenVPN tunnel: %@", startError);
          [weakSelf handleConnectionError];
          return;
        }

        NSLog(@"[VortexVPNManager] OpenVPN tunnel started");
      }];
    }];
  };

  // Check if we already have a tunnel manager
  if (self.tunnelManager) {
    configureAndConnect(self.tunnelManager);
  } else {
    // Create a new one
    NETunnelProviderManager* newManager = [[NETunnelProviderManager alloc] init];
    configureAndConnect(newManager);
  }
}

- (void)disconnect {
  if (self.status == VortexVPNStatusDisconnected) {
    return;
  }

  NSLog(@"[VortexVPNManager] Disconnect requested");

  // Disconnect both managers to be safe
  if (self.tunnelManager.connection.status != NEVPNStatusDisconnected) {
    [self.tunnelManager.connection stopVPNTunnel];
  }
  if (self.vpnManager.connection.status != NEVPNStatusDisconnected) {
    [self.vpnManager.connection stopVPNTunnel];
  }
}

- (void)handleConnectionError {
  @synchronized(self) {
    self.connectionInProgress = NO;
  }
  self.status = VortexVPNStatusError;
  [self notifyObservers];
}

#pragma mark - Server Fetch

- (void)fetchRandomServerWithCompletion:(void (^)(VortexVPNServer* _Nullable server,
                                                  NSError* _Nullable error))completion {
  NSURL* url = [NSURL URLWithString:VORTEX_RANDOM_SERVER_ENDPOINT_URL];
  if (!url) {
    if (completion) {
      NSError* err = [NSError errorWithDomain:@"VortexVPN"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
      completion(nil, err);
    }
    return;
  }

  NSLog(@"[VortexVPNManager] Fetching random server from: %@", url);

  NSURLSessionDataTask* task =
      [[NSURLSession sharedSession]
          dataTaskWithURL:url
        completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
          if (error) {
            NSLog(@"[VortexVPNManager] Random server fetch error: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion) completion(nil, error);
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
              if (completion) completion(nil, statusError);
            });
            return;
          }

          if (!data) {
            NSError* dataError = [NSError errorWithDomain:@"VortexVPN"
                                                     code:1003
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Empty response"}];
            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion) completion(nil, dataError);
            });
            return;
          }

          NSError* jsonError = nil;
          NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
          if (jsonError || ![dict isKindOfClass:[NSDictionary class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion) completion(nil, jsonError);
            });
            return;
          }

          NSLog(@"[VortexVPNManager] Random server response: %@", dict);

          // Parse server using the same model as the server list
          VortexVPNServer* server = [VortexVPNServer serverFromDictionary:dict];
          if (!server) {
            NSError* parseError = [NSError errorWithDomain:@"VortexVPN"
                                                      code:1004
                                                  userInfo:@{NSLocalizedDescriptionKey: @"Invalid server data"}];
            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion) completion(nil, parseError);
            });
            return;
          }

          if (!server.isOnline) {
            NSError* offlineError = [NSError errorWithDomain:@"VortexVPN"
                                                        code:1005
                                                    userInfo:@{NSLocalizedDescriptionKey: @"Server offline"}];
            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion) completion(nil, offlineError);
            });
            return;
          }

          NSLog(@"[VortexVPNManager] Random server: %@ (ovpnConfig: %@, psk: %@)",
                server.ip,
                server.ovpnConfig ? @"YES" : @"NO",
                server.psk ? @"YES" : @"NO");

          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(server, nil);
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

#pragma mark - Server Selection

- (void)setSelectedServer:(VortexVPNServer* _Nullable)server {
  _selectedServer = server;
}

- (void)clearSelectedServer {
  [self setSelectedServer:nil];
}

- (void)fetchAllServersWithCompletion:
    (void (^)(NSArray<VortexVPNServer*>* _Nullable servers,
              NSError* _Nullable error))completion {
  NSURL* url = [NSURL URLWithString:@"https://vortexbrowser.com/api/servers"];
  if (!url) {
    if (completion) {
      NSError* err = [NSError errorWithDomain:@"VortexVPN"
                                         code:1010
                                     userInfo:@{
                                       NSLocalizedDescriptionKey :
                                           @"Invalid servers URL"
                                     }];
      completion(nil, err);
    }
    return;
  }

  NSURLSessionDataTask* task =
      [[NSURLSession sharedSession]
          dataTaskWithURL:url
        completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
          if (error) {
            if (completion) {
              dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
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
            if (completion) {
              NSError* statusError =
                  [NSError errorWithDomain:@"VortexVPN"
                                      code:1011
                                  userInfo:@{NSLocalizedDescriptionKey : msg}];
              dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, statusError);
              });
            }
            return;
          }

          if (!data) {
            NSString* msg = @"Empty response body from servers endpoint";
            if (completion) {
              NSError* dataError =
                  [NSError errorWithDomain:@"VortexVPN"
                                      code:1012
                                  userInfo:@{NSLocalizedDescriptionKey : msg}];
              dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, dataError);
              });
            }
            return;
          }

          NSError* jsonError = nil;
          id json = [NSJSONSerialization JSONObjectWithData:data
                                                    options:0
                                                      error:&jsonError];
          if (jsonError || ![json isKindOfClass:[NSArray class]]) {
            if (completion) {
              dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, jsonError);
              });
            }
            return;
          }

          NSArray* serverDicts = (NSArray*)json;
          NSMutableArray<VortexVPNServer*>* servers =
              [NSMutableArray arrayWithCapacity:serverDicts.count];

          for (NSDictionary* dict in serverDicts) {
            VortexVPNServer* server = [VortexVPNServer serverFromDictionary:dict];
            if (server) {
              [servers addObject:server];
            }
          }

          dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
              completion([servers copy], nil);
            }
          });
        }];

  [task resume];
}

@end