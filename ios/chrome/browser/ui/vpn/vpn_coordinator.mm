#import "ios/chrome/browser/ui/vpn/vpn_coordinator.h"
#import "ios/chrome/browser/vortex_vpn/vortex_vpn_manager.h"
#import "ios/chrome/browser/vortex_plus/vortex_plus_manager.h"
#import "ios/chrome/browser/ui/vortex_paywall/vortex_paywall_coordinator.h"
#import "ios/chrome/browser/shared/public/commands/vpn_commands.h"

@interface VPNCoordinator () <VPNCommands, VortexPaywallCoordinatorDelegate>
@property(nonatomic, strong) VortexPaywallCoordinator* paywallCoordinator;
@end

@implementation VPNCoordinator

#pragma mark - VPNCommands

- (void)toggleVPN {
  VortexVPNManager* vpnManager = [VortexVPNManager sharedManager];

  if (vpnManager.isConnected) {
    [self disconnectVPN];
  } else {
    [self connectVPN];
  }
}

- (void)connectVPN {
  if ([[VortexPlusManager sharedManager] isPremium]) {
    [[VortexVPNManager sharedManager] connect];
  } else {
    [self showVPNPaywall];
  }
}

- (void)disconnectVPN {
  [[VortexVPNManager sharedManager] disconnect];
}

- (void)showVPNPaywall {
  if (self.paywallCoordinator) {
    NSLog(@"⚠️ [VPNCoordinator] Paywall already showing, ignoring");
    return;
  }

  UIViewController* base = [self topMostViewController];
  NSLog(@"🔵 [VPNCoordinator] topMostVC: %@", base);

  NSLog(@"🔵 [VPNCoordinator] Showing VPN paywall");
  NSLog(@"🔵 [VPNCoordinator] baseViewController: %@", self.baseViewController);

  self.paywallCoordinator = [[VortexPaywallCoordinator alloc]
      initWithBaseViewController:base
                         browser:self.browser];
  self.paywallCoordinator.delegate = self;

  NSLog(@"🔵 [VPNCoordinator] Starting paywall coordinator");
  [self.paywallCoordinator start];
}

- (UIViewController*)topMostViewController {
    // Find the active window scene
    NSSet<UIScene*>* scenes = UIApplication.sharedApplication.connectedScenes;
    UIWindowScene* activeScene = nil;

    for (UIScene* scene in scenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
            activeScene = (UIWindowScene*)scene;
            break;
        }
    }

    if (!activeScene) {
        // Fallback: first available UIWindowScene
        activeScene = (UIWindowScene*)scenes.anyObject;
    }

    if (!activeScene) return nil;

    // Get the key window (correct for multi-window setups)
    UIWindow* window = nil;
    for (UIWindow* w in activeScene.windows) {
        if (w.isKeyWindow) {
            window = w;
            break;
        }
    }

    if (!window) {
        window = activeScene.windows.firstObject;
    }

    UIViewController* top = window.rootViewController;
    if (!top) return nil;

    // Walk presented stack
    while (top.presentedViewController) {
        top = top.presentedViewController;
    }

    // Navigation controller handling
    if ([top isKindOfClass:[UINavigationController class]]) {
        UINavigationController* nav = (UINavigationController*)top;
        top = nav.visibleViewController ?: nav.topViewController ?: top;
    }

    // Tab bar controller handling
    if ([top isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tab = (UITabBarController*)top;
        top = tab.selectedViewController ?: top;
    }

    return top;
}

#pragma mark - VortexPaywallCoordinatorDelegate

- (void)vortexPaywallCoordinatorDidRequestClose:(VortexPaywallCoordinator*)coordinator {
  [self.paywallCoordinator stop];
  self.paywallCoordinator = nil;
}

- (void)vortexPaywallCoordinatorDidComplete:(VortexPaywallCoordinator*)coordinator {
  [self.paywallCoordinator stop];
  self.paywallCoordinator = nil;
  [[VortexVPNManager sharedManager] connect];
}

@end
