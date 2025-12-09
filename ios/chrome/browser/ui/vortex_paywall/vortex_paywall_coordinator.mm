// ios/chrome/browser/ui/vortex_paywall/vortex_paywall_coordinator.mm

#import "ios/chrome/browser/ui/vortex_paywall/vortex_paywall_coordinator.h"

#import "ios/chrome/browser/shared/model/browser/browser.h"
#import "ios/chrome/browser/ui/vortex_paywall/vortex_paywall_mediator.h"
#import "ios/chrome/browser/ui/vortex_paywall/vortex_paywall_view_controller.h"
#import "ios/chrome/browser/vortex_plus/vortex_plus_manager.h"
#import "third_party/revenuecat/ios/vortex_revenuecat_shim.h"

@interface VortexPaywallCoordinator () <VortexPaywallViewControllerDelegate>

// Strong references to our pieces.
@property(nonatomic, strong) VortexPaywallViewController* viewController;
@property(nonatomic, strong) VortexPaywallMediator* mediator;
@property(nonatomic, strong) UINavigationController* navigationController;
@property(nonatomic, strong) VortexPaywallViewController* paywallViewController;

@end

@implementation VortexPaywallCoordinator

- (instancetype)initWithBaseViewController:(UIViewController*)viewController
                                   browser:(Browser*)browser {
  self = [super initWithBaseViewController:viewController browser:browser];
  if (self) {
    // Nothing special yet.
  }
  return self;
}

- (void)start {
  [super start];

  NSLog(@"[VortexPaywallCoordinator] start");

  // Create view controller
  self.viewController = [[VortexPaywallViewController alloc] init];
  self.viewController.delegate = self;

  // Create mediator
  self.mediator = [[VortexPaywallMediator alloc] initWithBrowser:self.browser];
  self.mediator.consumer = self.viewController;

  // Wrap in navigation controller
  self.navigationController =
      [[UINavigationController alloc] initWithRootViewController:self.viewController];
  self.navigationController.modalPresentationStyle = UIModalPresentationFullScreen;

  // ⬇️ VORTEX: Find the topmost view controller
  UIViewController* presentingVC = [self topMostViewController];

  NSLog(@"[VortexPaywallCoordinator] presenting from: %@", presentingVC);

  __weak __typeof(self) weakSelf = self;
  [presentingVC presentViewController:self.navigationController
                              animated:YES
                            completion:^{
    NSLog(@"✅ [VortexPaywallCoordinator] Presentation completed");
    [weakSelf.mediator startLoadingDefaultOffering];
  }];
}

// Helper to find the topmost view controller
- (UIViewController*)topMostViewController {
  UIViewController* topVC = self.baseViewController;

  // If base VC is already presenting something, use that instead
  while (topVC.presentedViewController) {
    topVC = topVC.presentedViewController;
  }

  // If it's a navigation controller, use the top view controller
  if ([topVC isKindOfClass:[UINavigationController class]]) {
    UINavigationController* navController = (UINavigationController*)topVC;
    if (navController.topViewController) {
      topVC = navController.topViewController;
    }
  }

  // If it's a tab bar controller, use the selected view controller
  if ([topVC isKindOfClass:[UITabBarController class]]) {
    UITabBarController* tabController = (UITabBarController*)topVC;
    if (tabController.selectedViewController) {
      topVC = tabController.selectedViewController;
    }
  }

  return topVC;
}

- (void)stop {
  [super stop];

  [self.navigationController dismissViewControllerAnimated:YES
                                                completion:nil];
  self.navigationController = nil;
  self.paywallViewController = nil;
  self.mediator = nil;
}

#pragma mark - VortexPaywallViewControllerDelegate

- (void)vortexPaywallViewControllerDidRequestClose:
    (VortexPaywallViewController*)viewController {
    if ([self.delegate respondsToSelector:@selector(vortexPaywallCoordinatorDidRequestClose:)]) {
    [self.delegate vortexPaywallCoordinatorDidRequestClose:self];
  } else {
    [self stop];
  }

}

- (void)vortexPaywallViewController:(VortexPaywallViewController*)viewController
         didSelectPackageIdentifier:(NSString*)packageIdentifier {
  __weak __typeof(self) weakSelf = self;
  [self.mediator purchasePackageWithIdentifier:packageIdentifier
                             fromViewController:viewController
                                     completion:^(BOOL success,
                                                  NSError* error) {
                                       if (success) {
                                         NSLog(@"[VortexPaywallCoordinator] Purchase successful");
                                         [[VortexPlusManager sharedManager] syncWithRevenueCat];
                                         if ([weakSelf.delegate respondsToSelector:@selector(vortexPaywallCoordinatorDidComplete:)]) {
                                           [weakSelf.delegate vortexPaywallCoordinatorDidComplete:weakSelf];
                                         } else {
                                           [weakSelf stop];
                                         }

                                       } else {
                                         NSLog(@"[VortexPaywallCoordinator] Purchase failed: %@", error);
                                       }
                                     }];
}

- (void)vortexPaywallViewControllerDidRequestRestore:
    (VortexPaywallViewController*)viewController {
  __weak __typeof(self) weakSelf = self;
  NSLog(@"[VortexPaywallCoordinator] restore tapped");
  [VortexRevenueCatShim restorePurchasesWithCompletion:^(BOOL success, NSError* error) {
    if (error) {
      NSLog(@"[VortexPaywallCoordinator] Restore failed: %@", error);
      if ([weakSelf.delegate respondsToSelector:@selector(vortexPaywallCoordinatorDidRequestClose:)]) {
        [weakSelf.delegate vortexPaywallCoordinatorDidRequestClose:weakSelf];
      } else {
        [weakSelf stop];
      }
    }
    if (success) {
      NSLog(@"[VortexPaywallCoordinator] Restore successful");
      [[VortexPlusManager sharedManager] syncWithRevenueCat];
      if ([weakSelf.delegate respondsToSelector:@selector(vortexPaywallCoordinatorDidComplete:)]) {
        [weakSelf.delegate vortexPaywallCoordinatorDidComplete:weakSelf];
      } else {
        [weakSelf stop];
      }

    }
 }];
}

@end
