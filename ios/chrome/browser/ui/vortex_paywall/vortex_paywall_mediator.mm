// ios/chrome/browser/ui/vortex_paywall/vortex_paywall_mediator.mm

#import "ios/chrome/browser/ui/vortex_paywall/vortex_paywall_mediator.h"

#import "ios/chrome/browser/ui/vortex_paywall/vortex_paywall_view_controller.h"
#import "ios/chrome/browser/ui/vortex_paywall/vortex_paywall_item.h"
#import "third_party/revenuecat/ios/vortex_revenuecat_shim.h"
#import "ios/chrome/browser/shared/model/browser/browser.h"

@interface VortexPaywallMediator ()
@property(nonatomic, assign) Browser* browser;
@end

@implementation VortexPaywallMediator

- (instancetype)initWithBrowser:(Browser*)browser {
  self = [super init];
  if (self) {
    _browser = browser;
    NSLog(@"[VortexPaywallMediator] initWithBrowser:%p", browser);
  }
  return self;
}

- (void)startLoadingDefaultOffering {
  NSLog(@"[VortexPaywallMediator] startLoadingDefaultOffering (consumer=%@)",
        self.consumer);
  if (!self.consumer) {
    return;
  }

  [self.consumer showLoading];

  [VortexRevenueCatShim loadDefaultOfferingWithCompletion:^(
                           NSArray<VortexProductInfo*>* products,
                           NSError* error) {
    NSLog(@"[VortexPaywallMediator] completion called. error=%@ products=%lu",
          error, (unsigned long)products.count);
    dispatch_async(dispatch_get_main_queue(), ^{
      if (!self.consumer) {
        return;
      }

      if (error || products.count == 0) {
        NSLog(@"[VortexPaywallMediator] error or empty products, showing error");
        [self.consumer
            showErrorMessage:@"Unable to load offers. Please try again later."];
        return;
      }

      NSMutableArray<VortexPaywallPackageItem*>* items =
          [NSMutableArray arrayWithCapacity:products.count];

      for (VortexProductInfo* info in products) {
        VortexPaywallPackageItem* item = [[VortexPaywallPackageItem alloc] init];
        item.identifier = info.identifier;
        item.title = info.title;
        item.subtitle = info.subtitle;
        item.priceString = info.priceText;
        item.recommended = info.recommended;
        item.hasTrial = info.hasTrial;
        [items addObject:item];
      }

      NSLog(@"[VortexPaywallMediator] mapped %lu items, calling showPackages",
          (unsigned long)items.count);
      [self.consumer showPackages:items];
    });
  }];
}

- (void)purchasePackageWithIdentifier:(NSString*)identifier
                    fromViewController:(UIViewController*)viewController
                            completion:(void (^)(BOOL success,
                                                 NSError* _Nullable error))
                                           completion {
  NSLog(@"[VortexPaywallMediator] purchasePackageWithIdentifier:%@",
    identifier);
    
  [VortexRevenueCatShim purchasePackageWithIdentifier:identifier
                                    fromViewController:viewController
                                            completion:completion];
}

@end
