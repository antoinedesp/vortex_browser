#import "ios/chrome/app/vortex_revenuecat_initializer.h"
#import "third_party/revenuecat/ios/vortex_revenuecat_shim.h"
#import "ios/third_party/vortex/src/vortex_constants.h"

@implementation VortexRevenueCatInitializer

+ (void)configureRevenueCat {
    [VortexRevenueCatShim configureWithApiKey:VORTEX_REVENUECAT_API_KEY appUserID:nil];
}

@end
