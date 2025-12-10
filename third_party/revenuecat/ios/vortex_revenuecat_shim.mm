// Copyright 2025 Vortex Softwares Ltd
// Use of this source code is prohibited

#import "third_party/revenuecat/ios/vortex_revenuecat_shim.h"
#import <dispatch/dispatch.h>
#import <StoreKit/StoreKit.h>
#import "RevenueCat-Swift.h"

NS_ASSUME_NONNULL_BEGIN

#define HAS_REVENUECAT 1

#pragma mark - VortexProductInfo

@implementation VortexProductInfo

- (instancetype)initWithIdentifier:(NSString*)identifier
                             title:(NSString*)title
                          subtitle:(NSString*)subtitle
                         priceText:(NSString*)priceText
                       recommended:(BOOL)recommended
                       hasTrial:(BOOL)hasTrial {
  self = [super init];
  if (self) {
    _identifier = [identifier copy];
    _title = [title copy];
    _subtitle = [subtitle copy];
    _priceText = [priceText copy];
    _recommended = recommended;
    _hasTrial = hasTrial;
  }
  return self;
}

- (NSString*)description {
  return [NSString stringWithFormat:
      @"<VortexProductInfo: %@ - %@ (%@)%@%@>",
      self.identifier, self.title, self.priceText,
      self.recommended ? @" [RECOMMENDED]" : @"",
      self.hasTrial ? @" [TRIAL]" : @""];
}

@end

#pragma mark - VortexRevenueCatShim

@interface VortexRevenueCatShim ()
+ (NSString*)unitStringForPeriodUnit:(RCSubscriptionPeriodUnit)unit;
+ (NSString*)titleForPackageType:(RCPackageType)packageType;
+ (NSString*)subtitleForPackageType:(RCPackageType)packageType;
@end

@implementation VortexRevenueCatShim

static NSString* gApiKey = nil;
static NSString* gUserId = nil;
static NSString* kPremiumEntitlementID = @"premium";

#pragma mark - Configuration

+ (void)configureWithApiKey:(NSString*)apiKey
                  appUserID:(NSString* _Nullable)appUserID {
  if (!apiKey || apiKey.length == 0) {
    NSLog(@"[VortexRevenueCatShim] ERROR: API key is required");
    return;
  }

  gApiKey = [apiKey copy];
  gUserId = [appUserID copy];

  NSLog(@"[VortexRevenueCatShim] Configuring with API key: %@ user: %@",
        gApiKey, gUserId ?: @"<anonymous>");

#if HAS_REVENUECAT
  [RCPurchases configureWithAPIKey:gApiKey appUserID:gUserId];
  NSLog(@"[VortexRevenueCatShim] RevenueCat SDK configured");
#else
  NSLog(@"[VortexRevenueCatShim] RevenueCat SDK not available - using stub");
#endif
}

#pragma mark - Premium Status

+ (void)isUserPremiumWithCompletion:(void (^)(BOOL isPremium,
                                              NSError* _Nullable error))completion {
  if (!completion) {
    NSLog(@"[VortexRevenueCatShim] ERROR: completion block is required");
    return;
  }

#if HAS_REVENUECAT
  [[RCPurchases sharedPurchases]
      getCustomerInfoWithCompletion:^(RCCustomerInfo* _Nullable customerInfo,
                                      NSError* _Nullable error) {
    if (error) {
      NSLog(@"[VortexRevenueCatShim] Error fetching customer info: %@",
            error.localizedDescription);
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(NO, error);
      });
      return;
    }

    BOOL isPremium = NO;
    if (customerInfo.entitlements[kPremiumEntitlementID]) {
      isPremium = customerInfo.entitlements[kPremiumEntitlementID].isActive;
    }

    NSLog(@"[VortexRevenueCatShim] User premium status: %@",
          isPremium ? @"YES" : @"NO");

    dispatch_async(dispatch_get_main_queue(), ^{
      completion(isPremium, nil);
    });
  }];
#else
  // Stub implementation: always return NO (non-premium)
  NSLog(@"[VortexRevenueCatShim] Stub: returning non-premium status");
  dispatch_async(dispatch_get_main_queue(), ^{
    completion(NO, nil);
  });
#endif
}

#pragma mark - Offerings

+ (void)loadDefaultOfferingWithCompletion:
    (void (^)(NSArray<VortexProductInfo*>* _Nullable items,
              NSError* _Nullable error))completion {
  if (!completion) {
    NSLog(@"[VortexRevenueCatShim] ERROR: completion block is required");
    return;
  }

  NSLog(@"[VortexRevenueCatShim] Loading default offering...");

#if HAS_REVENUECAT
  [[RCPurchases sharedPurchases]
      getOfferingsWithCompletion:^(RCOfferings* _Nullable offerings,
                                   NSError* _Nullable error) {
    if (error) {
      NSLog(@"[VortexRevenueCatShim] Error loading offerings: %@",
            error.localizedDescription);
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil, error);
      });
      return;
    }

    if (!offerings.current || offerings.current.availablePackages.count == 0) {
      NSLog(@"[VortexRevenueCatShim] No offerings available");
      NSError* noOfferingsError = [NSError
          errorWithDomain:@"VortexRevenueCatShim"
                     code:404
                 userInfo:@{
                   NSLocalizedDescriptionKey: @"No offerings available"
                 }];
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil, noOfferingsError);
      });
      return;
    }

    // Convert RCPackage objects to VortexProductInfo
    NSMutableArray<VortexProductInfo*>* products = [NSMutableArray array];
    for (RCPackage* package in offerings.current.availablePackages) {
      NSString* title = [self titleForPackageType:package.packageType];
      NSString* subtitle = [self subtitleForPackageType:package.packageType];
      BOOL isRecommended =
          (package.packageType == RCPackageTypeAnnual ||
           package.packageType == RCPackageTypeSixMonth);
      BOOL hasTrial = NO;
      if (package.storeProduct.introductoryDiscount) {
        RCStoreProductDiscount* intro = package.storeProduct.introductoryDiscount;
        if([intro.price compare:@0] == NSOrderedSame) {
          hasTrial = YES;
          NSLog(@"[VortexRevenueCatShim] Product %@ has free trial: %@ %@",
               package.identifier,
               @(intro.subscriptionPeriod.value),
               [self unitStringForPeriodUnit:intro.subscriptionPeriod.unit]);
        }
      }

      VortexProductInfo* productInfo = [[VortexProductInfo alloc]
        initWithIdentifier:package.identifier
            title:title
            subtitle:subtitle
            priceText:package.localizedPriceString
            recommended:isRecommended
            hasTrial:hasTrial];

      [products addObject:productInfo];
    }

    NSLog(@"[VortexRevenueCatShim] Loaded %lu products",
          (unsigned long)products.count);

    dispatch_async(dispatch_get_main_queue(), ^{
      completion([products copy], nil);
    });
  }];
#else
  // Stub implementation: return mock products
  [self loadStubOfferingsWithCompletion:completion];
#endif
}

+ (NSString*)titleForPackageType:(RCPackageType)packageType {
    switch (packageType) {
      case RCPackageTypeWeekly:
        return @"Weekly";
      case RCPackageTypeMonthly:
        return @"Monthly";
      case RCPackageTypeTwoMonth:
        return @"2 Months";
      case RCPackageTypeThreeMonth:
        return @"3 Months";
      case RCPackageTypeSixMonth:
        return @"6 Months";
      case RCPackageTypeAnnual:
        return @"Yearly";
      case RCPackageTypeLifetime:
        return @"Lifetime";
      default:
        return @"";

    }
}

+ (NSString*)subtitleForPackageType:(RCPackageType)packageType {
  switch (packageType) {
    case RCPackageTypeMonthly:
      return @"Billed monthly. Cancel anytime.";
    case RCPackageTypeTwoMonth:
      return @"Billed every 2 months.";
    case RCPackageTypeThreeMonth:
      return @"Billed every 3 months.";
    case RCPackageTypeSixMonth:
      return @"6 months for a great price.";
    case RCPackageTypeAnnual:
      return @"Billed yearly. Cancel anytime.";
    case RCPackageTypeWeekly:
      return @"Billed weekly.";
    case RCPackageTypeLifetime:
      return @"One-time purchase. Lifetime access.";
    default:
      return @"";
  }
}

+ (void)loadStubOfferingsWithCompletion:
    (void (^)(NSArray<VortexProductInfo*>* _Nullable items,
              NSError* _Nullable error))completion {
  NSLog(@"[VortexRevenueCatShim] Loading stub offerings...");

  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
    VortexProductInfo* monthly = [[VortexProductInfo alloc]
        initWithIdentifier:@"vortex_plus_monthly"
            title:@"Vortex Plus Monthly"
            subtitle:@"Billed monthly. Cancel anytime."
            priceText:@"€4.99 / month"
            recommended:NO
            hasTrial:NO];

    VortexProductInfo* yearly = [[VortexProductInfo alloc]
        initWithIdentifier:@"vortex_plus_yearly"
            title:@"Vortex Plus Yearly"
            subtitle:@"12 months for the price of 8."
            priceText:@"€39.99 / year"
            recommended:YES
            hasTrial:YES];

    NSLog(@"[VortexRevenueCatShim] Returning stub offerings");
    completion(@[ monthly, yearly ], nil);
  });
}

#pragma mark - Purchase

+ (void)purchasePackageWithIdentifier:(NSString*)identifier
                   fromViewController:(UIViewController*)viewController
                           completion:(void (^)(BOOL success,
                                                NSError* _Nullable error))
                                          completion {
  if (!identifier || identifier.length == 0) {
    NSLog(@"[VortexRevenueCatShim] ERROR: identifier is required");
    if (completion) {
      NSError* error = [NSError
          errorWithDomain:@"VortexRevenueCatShim"
                     code:400
                 userInfo:@{
                   NSLocalizedDescriptionKey: @"Package identifier is required"
                 }];
      completion(NO, error);
    }
    return;
  }

  if (!completion) {
    NSLog(@"[VortexRevenueCatShim] ERROR: completion block is required");
    return;
  }

  NSLog(@"[VortexRevenueCatShim] Purchasing package: %@", identifier);

#if HAS_REVENUECAT
  // First, load offerings to find the package
  [[RCPurchases sharedPurchases]
      getOfferingsWithCompletion:^(RCOfferings* _Nullable offerings,
                                   NSError* _Nullable error) {
    if (error || !offerings.current) {
      NSLog(@"[VortexRevenueCatShim] Error loading offerings for purchase: %@",
            error.localizedDescription);
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(NO, error);
      });
      return;
    }

    // Find the package by identifier
    RCPackage* targetPackage = nil;
    for (RCPackage* package in offerings.current.availablePackages) {
      if ([package.identifier isEqualToString:identifier]) {
        targetPackage = package;
        break;
      }
    }

    if (!targetPackage) {
      NSLog(@"[VortexRevenueCatShim] Package not found: %@", identifier);
      NSError* notFoundError = [NSError
          errorWithDomain:@"VortexRevenueCatShim"
                     code:404
                 userInfo:@{
                   NSLocalizedDescriptionKey:
                       [NSString stringWithFormat:@"Package not found: %@",
                                                  identifier]
                 }];
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(NO, notFoundError);
      });
      return;
    }

    // Purchase the package
    [[RCPurchases sharedPurchases]
        purchasePackage:targetPackage
         withCompletion:^(RCStoreTransaction* _Nullable transaction,
                          RCCustomerInfo* _Nullable customerInfo,
                          NSError* _Nullable purchaseError,
                          BOOL userCancelled) {
      if (userCancelled) {
        NSLog(@"[VortexRevenueCatShim] Purchase cancelled by user");
        dispatch_async(dispatch_get_main_queue(), ^{
          NSError* cancelError = [NSError
              errorWithDomain:@"VortexRevenueCatShim"
                         code:1
                     userInfo:@{
                       NSLocalizedDescriptionKey: @"Purchase cancelled"
                     }];
          completion(NO, cancelError);
        });
        return;
      }

      if (purchaseError) {
        NSLog(@"[VortexRevenueCatShim] Purchase error: %@",
              purchaseError.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
          completion(NO, purchaseError);
        });
        return;
      }

      // Check if premium entitlement is now active
      BOOL isPremium = NO;
      if (customerInfo.entitlements[kPremiumEntitlementID]) {
        isPremium =
            customerInfo.entitlements[kPremiumEntitlementID].isActive;
      }

      NSLog(@"[VortexRevenueCatShim] Purchase successful. Premium: %@",
            isPremium ? @"YES" : @"NO");

      dispatch_async(dispatch_get_main_queue(), ^{
        completion(YES, nil);
      });
    }];
  }];
#else
  // Stub implementation: simulate successful purchase
  [self stubPurchaseWithIdentifier:identifier completion:completion];
#endif
}

+ (void)stubPurchaseWithIdentifier:(NSString*)identifier
                        completion:(void (^)(BOOL success,
                                             NSError* _Nullable error))
                                       completion {
  NSLog(@"[VortexRevenueCatShim] Stub: simulating purchase for %@", identifier);

  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
    NSLog(@"[VortexRevenueCatShim] Stub: purchase successful");
    completion(YES, nil);
  });
}

+ (NSString*)unitStringForPeriodUnit:(RCSubscriptionPeriodUnit)unit {
    switch(unit) {
        case RCSubscriptionPeriodUnitDay:
          return @"day(s)";
        case RCSubscriptionPeriodUnitWeek:
          return @"week(s)";
        case RCSubscriptionPeriodUnitMonth:
          return @"month(s)";
        case RCSubscriptionPeriodUnitYear:
          return @"year(s)";
        default:
          return @"period(s)";
    }
}

#pragma mark - Restore

+ (void)restorePurchasesWithCompletion:(void (^)(BOOL success,
                                                 NSError* _Nullable error))
                                           completion {
  if (!completion) {
    NSLog(@"[VortexRevenueCatShim] ERROR: completion block is required");
    return;
  }

  NSLog(@"[VortexRevenueCatShim] Restoring purchases...");

#if HAS_REVENUECAT
  [[RCPurchases sharedPurchases]
      restorePurchasesWithCompletion:^(RCCustomerInfo* _Nullable customerInfo,
                                       NSError* _Nullable error) {
    if (error) {
      NSLog(@"[VortexRevenueCatShim] Restore error: %@",
            error.localizedDescription);
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(NO, error);
      });
      return;
    }

    BOOL isPremium = NO;
    if (customerInfo.entitlements[kPremiumEntitlementID]) {
      isPremium = customerInfo.entitlements[kPremiumEntitlementID].isActive;
    }

    NSLog(@"[VortexRevenueCatShim] Restore successful. Premium: %@",
          isPremium ? @"YES" : @"NO");

    dispatch_async(dispatch_get_main_queue(), ^{
      completion(YES, nil);
    });
  }];
#else
  // Stub implementation
  NSLog(@"[VortexRevenueCatShim] Stub: restore successful");
  dispatch_async(dispatch_get_main_queue(), ^{
    completion(YES, nil);
  });
#endif
}

@end

NS_ASSUME_NONNULL_END