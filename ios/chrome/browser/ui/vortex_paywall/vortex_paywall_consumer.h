// vortex_paywall_consumer.h

#import <Foundation/Foundation.h>
#import "ios/chrome/browser/ui/vortex_paywall/vortex_paywall_item.h"

@class VortexProductInfo;

NS_ASSUME_NONNULL_BEGIN

@protocol VortexPaywallConsumer <NSObject>

// Show a loading spinner / skeleton.
- (void)showLoading;

// Show a simple error message.
- (void)showErrorMessage:(NSString *)message;

// Display the list of purchasable packages.
- (void)showPackages:(NSArray<VortexPaywallPackageItem*>*)packages;

@end

NS_ASSUME_NONNULL_END
