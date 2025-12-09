#import "ios/chrome/app/vortex_revenuecat_initializer.h"
#import "third_party/revenuecat/ios/vortex_revenuecat_shim.h"

@implementation VortexRevenueCatInitializer

+ (void)configureRevenueCat {
#if DEBUG
    NSString *apiKey = @"appl_wEdjzBbxSyYcdvkWJEqFlEpRoAt";
#else
    NSString *apiKey = @"appl_wEdjzBbxSyYcdvkWJEqFlEpRoAt";
#endif
    // For now you can use anonymous users (nil appUserID) or derive from Chrome profile later.
    [VortexRevenueCatShim configureWithApiKey:apiKey appUserID:nil];
}

@end
