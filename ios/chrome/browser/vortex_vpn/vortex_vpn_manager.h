// ios/chrome/browser/vortex_vpn/vortex_vpn_manager.h

#import <Foundation/Foundation.h>

@class VortexVPNServer;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VortexVPNStatus) {
  VortexVPNStatusDisconnected = 0,
  VortexVPNStatusConnecting,
  VortexVPNStatusConnected,
  VortexVPNStatusError,
};

@protocol VortexVPNObserver <NSObject>
- (void)vpnManagerDidUpdateStatus:(VortexVPNStatus)status;
@end

@interface VortexVPNManager : NSObject

@property(nonatomic, assign, readonly) VortexVPNStatus status;

@property(nonatomic, readonly) BOOL isConnected;

// The currently selected server (nil means use random/auto selection).
@property(nonatomic, strong, nullable, readonly) VortexVPNServer* selectedServer;

+ (instancetype)sharedManager;

- (void)addObserver:(id<VortexVPNObserver>)observer;
- (void)removeObserver:(id<VortexVPNObserver>)observer;

// Connection control
- (void)connect;
- (void)disconnect;
- (void)toggle;

- (void)configureWithServer:(NSString*)serverAddress
               sharedSecret:(NSString*)sharedSecret
                   username:(NSString*)username
                   password:(NSString*)password
          completionHandler:(void (^)(BOOL success, NSError* _Nullable error))completion;

- (BOOL)isConfigured;

// Server selection
// Sets the server to use for future connections.
- (void)setSelectedServer:(VortexVPNServer* _Nullable)server;

// Clears the selected server (will use random/auto selection).
- (void)clearSelectedServer;

// Fetches all available servers from the API.
- (void)fetchAllServersWithCompletion:
    (void (^)(NSArray<VortexVPNServer*>* _Nullable servers,
              NSError* _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
