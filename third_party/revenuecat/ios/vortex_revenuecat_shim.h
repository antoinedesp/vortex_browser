// Copyright 2025 Vortex Softwares Ltd
// Use of this source code is prohibited

#ifndef THIRD_PARTY_REVENUECAT_IOS_VORTEX_REVENUECAT_SHIM_H_
#define THIRD_PARTY_REVENUECAT_IOS_VORTEX_REVENUECAT_SHIM_H_

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Represents a single in-app purchase product/package.
@interface VortexProductInfo : NSObject

@property(nonatomic, copy, readonly) NSString* identifier;
@property(nonatomic, copy, readonly) NSString* title;
@property(nonatomic, copy, readonly) NSString* subtitle;
@property(nonatomic, copy, readonly) NSString* priceText;
@property(nonatomic, assign, readonly) BOOL recommended;
@property(nonatomic, assign, readonly) BOOL hasTrial;

- (instancetype)initWithIdentifier:(NSString*)identifier
                             title:(NSString*)title
                          subtitle:(NSString*)subtitle
                         priceText:(NSString*)priceText
                       recommended:(BOOL)recommended
                       hasTrial:(BOOL)hasTrial;

@end

/// Shim layer for RevenueCat SDK integration.
/// Provides a simplified interface for checking premium status,
/// loading offerings, and purchasing packages.
@interface VortexRevenueCatShim : NSObject

/// Checks if the current user has an active premium entitlement.
/// @param completion Block called with the premium status or error.
+ (void)isUserPremiumWithCompletion:(void (^)(BOOL isPremium,
                                              NSError* _Nullable error))completion;

/// Configures the RevenueCat SDK with API key and optional user ID.
/// @param apiKey The RevenueCat public API key.
/// @param appUserID Optional user identifier. Pass nil for anonymous users.
+ (void)configureWithApiKey:(NSString*)apiKey
                  appUserID:(NSString* _Nullable)appUserID;

/// Loads the default offering (available packages).
/// @param completion Block called with an array of VortexProductInfo or error.
+ (void)loadDefaultOfferingWithCompletion:
    (void (^)(NSArray<VortexProductInfo*>* _Nullable items,
              NSError* _Nullable error))completion;

/// Purchases a package by identifier.
/// @param identifier The package identifier (e.g., "vortex_plus_monthly").
/// @param viewController The view controller to present purchase UI from.
/// @param completion Block called with success status and optional error.
+ (void)purchasePackageWithIdentifier:(NSString*)identifier
                   fromViewController:(UIViewController*)viewController
                           completion:(void (^)(BOOL success,
                                                NSError* _Nullable error))
                                          completion;

/// Restores previous purchases for the current user.
/// @param completion Block called with success status and optional error.
+ (void)restorePurchasesWithCompletion:(void (^)(BOOL success,
                                                 NSError* _Nullable error))
                                           completion;

/// Sets the Firebase App Instance ID for server-side analytics integration.
/// This enables RevenueCat to send subscription lifecycle events to Google Analytics.
/// Must be called after configureWithApiKey and after Firebase is configured.
/// @param appInstanceID The Firebase App Instance ID from FIRAnalytics.appInstanceID().
+ (void)setFirebaseAppInstanceID:(NSString*)appInstanceID;

@end

NS_ASSUME_NONNULL_END

#endif  // THIRD_PARTY_REVENUECAT_IOS_VORTEX_REVENUECAT_SHIM_H_