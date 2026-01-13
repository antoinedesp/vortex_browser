#import "ios/chrome/app/vortex_revenuecat_initializer.h"
#import "third_party/revenuecat/ios/vortex_revenuecat_shim.h"
#import "third_party/firebase/ios/vortex_firebase_analytics_shim.h"
#import "ios/third_party/vortex/src/vortex_constants.h"

@implementation VortexRevenueCatInitializer

+ (void)configureRevenueCat {
    // Configure RevenueCat SDK
    [VortexRevenueCatShim configureWithApiKey:VORTEX_REVENUECAT_API_KEY appUserID:nil];

    // Link Firebase Analytics with RevenueCat for server-side event tracking.
    // This enables RevenueCat to send subscription lifecycle events
    // (purchases, trials, renewals, cancellations, etc.) to Google Analytics.
    // See: https://www.revenuecat.com/docs/integrations/third-party-integrations/firebase-integration
    NSString *firebaseAppInstanceID = [VortexFirebaseAnalyticsShim appInstanceID];
    if (firebaseAppInstanceID) {
        [VortexRevenueCatShim setFirebaseAppInstanceID:firebaseAppInstanceID];
    } else {
        NSLog(@"[VortexRevenueCatInitializer] WARNING: Firebase App Instance ID not available. "
              @"Ensure Firebase is configured before RevenueCat.");
    }
}

@end
