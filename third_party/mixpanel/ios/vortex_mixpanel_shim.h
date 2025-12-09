// Copyright 2025 Vortex Softwares Ltd
// Use of this source code is prohibited

#ifndef THIRD_PARTY_MIXPANEL_IOS_VORTEX_MIXPANEL_SHIM_H_
#define THIRD_PARTY_MIXPANEL_IOS_VORTEX_MIXPANEL_SHIM_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Shim layer for Mixpanel Swift SDK integration.
/// Provides a simplified interface for configuring Mixpanel,
/// identifying users, tracking events and setting user properties.
@interface VortexMixpanelShim : NSObject

/// Configures the Mixpanel SDK with project token and optional user id.
/// Safe to call multiple times (reconfiguration is ignored if token/user
/// don’t change).
/// @param token Mixpanel project token.
/// @param userId Optional distinct id for the current user.
+ (void)configureWithToken:(NSString *)token
                    userId:(NSString * _Nullable)userId;

/// Updates the current Mixpanel distinct id.
/// If configureWithToken:… wasn’t called yet, this will be applied after
/// the first successful configuration.
+ (void)identifyUserWithId:(NSString * _Nullable)userId;

/// Tracks an event with optional properties.
/// @param event Event name.
/// @param properties Optional dictionary of event properties.
+ (void)trackEvent:(NSString *)event
        properties:(NSDictionary<NSString *, id> * _Nullable)properties;

/// Convenience helper to track a “screen view” style event.
/// In Mixpanel there is no native screen API, so this simply sends an event.
+ (void)trackScreen:(NSString *)screenName
         properties:(NSDictionary<NSString *, id> * _Nullable)properties;

/// Sets a single user profile property.
+ (void)setUserProperty:(NSString *)key
                  value:(id _Nullable)value;

/// Sets multiple user profile properties at once.
/// This assumes identify was called at least once.
+ (void)setUserProperties:(NSDictionary<NSString *, id> * _Nullable)properties;

/// Forces an immediate flush of queued events/profiles.
+ (void)flush;

/// Resets Mixpanel state (distinct id, super props, etc.).
/// Useful on logout.
+ (void)reset;

@end

NS_ASSUME_NONNULL_END

#endif  // THIRD_PARTY_MIXPANEL_IOS_VORTEX_MIXPANEL_SHIM_H_
