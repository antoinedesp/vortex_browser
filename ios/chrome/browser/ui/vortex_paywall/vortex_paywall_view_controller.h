// ios/chrome/browser/ui/vortex_paywall/vortex_paywall_view_controller.h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "vortex_paywall_consumer.h"

@class VortexPaywallViewController;
@class VortexProductInfo;  // From VortexRevenueCatShim

NS_ASSUME_NONNULL_BEGIN

@protocol VortexPaywallViewControllerDelegate <NSObject>

// User tapped the close button.
- (void)vortexPaywallViewControllerDidRequestClose:
    (VortexPaywallViewController*)viewController;

// User tapped a package/card button.
- (void)vortexPaywallViewController:(VortexPaywallViewController*)viewController
           didSelectPackageIdentifier:(NSString*)identifier;

- (void)vortexPaywallViewControllerDidRequestRestore:(VortexPaywallViewController*)viewController;

@end

@interface VortexPaywallViewController
    : UIViewController <VortexPaywallConsumer>

@property(nonatomic, weak) id<VortexPaywallViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
