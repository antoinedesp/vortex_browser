// Copyright 2025 Vortex Softwares Ltd
// Use of this source code is prohibited

#ifndef THIRD_PARTY_FIREBASE_IOS_VORTEX_FIREBASE_ANALYTICS_SHIM_H_
#define THIRD_PARTY_FIREBASE_IOS_VORTEX_FIREBASE_ANALYTICS_SHIM_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Shim layer for Firebase Analytics SDK integration.
/// Provides a simplified interface for configuring Firebase Analytics,
/// identifying users, logging events and setting user properties.
@interface VortexFirebaseAnalyticsShim : NSObject

/// Configures Firebase Analytics. Should be called once at app launch.
/// This initializes the Firebase SDK and enables analytics collection.
+ (void)configure;

/// Sets the user ID for analytics.
/// Pass nil to clear the user ID.
/// @param userId The user identifier to associate with analytics events.
+ (void)setUserId:(NSString *_Nullable)userId;

/// Logs an analytics event with optional parameters.
/// @param event Event name (max 40 characters, alphanumeric and underscores).
/// @param parameters Optional dictionary of event parameters.
+ (void)logEvent:(NSString *)event
      parameters:(NSDictionary<NSString *, id> *_Nullable)parameters;

/// Logs a screen view event.
/// @param screenName The name of the screen being viewed.
/// @param screenClass Optional screen class name.
+ (void)logScreenView:(NSString *)screenName
          screenClass:(NSString *_Nullable)screenClass;

/// Sets a user property value.
/// @param name Property name (max 24 characters).
/// @param value Property value (max 36 characters), or nil to clear.
+ (void)setUserPropertyString:(NSString *_Nullable)value
                      forName:(NSString *)name;

/// Enables or disables analytics collection.
/// @param enabled YES to enable, NO to disable.
+ (void)setAnalyticsCollectionEnabled:(BOOL)enabled;

/// Resets analytics data (clears user ID and user properties).
+ (void)reset;

@end

NS_ASSUME_NONNULL_END

#endif  // THIRD_PARTY_FIREBASE_IOS_VORTEX_FIREBASE_ANALYTICS_SHIM_H_
