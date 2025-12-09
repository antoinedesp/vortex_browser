// ios/chrome/browser/ui/vortex_paywall/vortex_paywall_mediator.h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Browser is a C++ class, so forward declare it as such.
#ifdef __cplusplus
class Browser;
#endif

@protocol VortexPaywallConsumer;

NS_ASSUME_NONNULL_BEGIN

@interface VortexPaywallMediator : NSObject

@property(nonatomic, weak) id<VortexPaywallConsumer> consumer;

- (instancetype)initWithBrowser:(Browser*)browser NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)startLoadingDefaultOffering;

- (void)purchasePackageWithIdentifier:(NSString*)identifier
                    fromViewController:(UIViewController*)viewController
                            completion:(void (^)(BOOL success,
                                                 NSError* _Nullable error))
                                           completion;
@end

NS_ASSUME_NONNULL_END
