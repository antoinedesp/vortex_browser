#import "ios/chrome/browser/shared/coordinator/chrome_coordinator/chrome_coordinator.h"

class Browser;

@class VortexPaywallMediator;
@class VortexPaywallViewController;
@class VortexPaywallCoordinator;


@protocol VortexPaywallCoordinatorDelegate <NSObject>

// Called when the user closes the paywall without purchasing
- (void)vortexPaywallCoordinatorDidRequestClose:(VortexPaywallCoordinator*)coordinator;

// Called when the user successfully purchases or restores
- (void)vortexPaywallCoordinatorDidComplete:(VortexPaywallCoordinator*)coordinator;

@end

@interface VortexPaywallCoordinator : ChromeCoordinator
@property(nonatomic, weak) id<VortexPaywallCoordinatorDelegate> delegate;

- (instancetype)initWithBaseViewController:(UIViewController*)viewController
                                   browser:(Browser*)browser
    NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithBaseViewController:(UIViewController*)viewController
    NS_UNAVAILABLE;

@end

