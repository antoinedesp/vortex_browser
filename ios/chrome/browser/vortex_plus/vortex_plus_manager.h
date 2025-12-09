// ios/chrome/browser/vortex_plus/vortex_plus_manager.h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VortexPlusStatus) {
  VortexPlusStatusEnabled = 0,
  VortexPlusStatusDisabled,
};

@protocol VortexPlusObserver <NSObject>
- (void)vortexPlusManagerDidUpdateIsVortexPlusEnabled:(BOOL)isVortexPlusEnabled;
@end

@interface VortexPlusManager : NSObject

@property(nonatomic, assign, readonly) BOOL isVortexPlusEnabled;

+ (instancetype)sharedManager;

- (void)addObserver:(id<VortexPlusObserver>)observer;
- (void)removeObserver:(id<VortexPlusObserver>)observer;

@property(nonatomic, readonly) BOOL isPremium;

// Fake API for now TODO: remove for prod
- (void)enablePlus;
- (void)disablePlus;

// RevenueCat integration
- (void)syncWithRevenueCat;

@end

NS_ASSUME_NONNULL_END
