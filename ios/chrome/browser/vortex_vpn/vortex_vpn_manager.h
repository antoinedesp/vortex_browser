// ios/chrome/browser/vortex_vpn/vortex_vpn_manager.h

#import <Foundation/Foundation.h>

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

+ (instancetype)sharedManager;

- (void)addObserver:(id<VortexVPNObserver>)observer;
- (void)removeObserver:(id<VortexVPNObserver>)observer;

// Connection control
- (void)connect;
- (void)disconnect;
- (void)toggle;

- (void)configureWithServer:(NSString*)serverAddress
                sharedSecret:(NSString*)sharedSecret
          completionHandler:(void (^)(BOOL success, NSError* _Nullable error))completion;

- (BOOL)isConfigured;

@end

NS_ASSUME_NONNULL_END
