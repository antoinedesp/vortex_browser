// ios/chrome/browser/ui/vortex_paywall/vortex_paywall_item.h
#import <Foundation/Foundation.h>

@interface VortexPaywallPackageItem : NSObject
@property(nonatomic, copy) NSString* title;
@property(nonatomic, copy) NSString* subtitle;
@property(nonatomic, copy) NSString* identifier;
@property(nonatomic, assign) BOOL recommended;
@property(nonatomic, copy) NSString* priceString;
@property(nonatomic, assign) BOOL hasTrial;

@end
