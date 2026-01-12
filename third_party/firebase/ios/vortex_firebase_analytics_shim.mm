// Copyright 2025 Vortex Softwares Ltd
// Use of this source code is prohibited

#import "third_party/firebase/ios/vortex_firebase_analytics_shim.h"

#import <Foundation/Foundation.h>

// Firebase headers (from include_dirs in BUILD.gn)
#import "FirebaseCore.h"
#import "FIRAnalytics.h"
#import "FIREventNames.h"
#import "FIRParameterNames.h"

NS_ASSUME_NONNULL_BEGIN

@implementation VortexFirebaseAnalyticsShim

static BOOL gConfigured = NO;

#pragma mark - Configuration

+ (void)configure {
  if (gConfigured) {
    NSLog(@"[VortexFirebaseAnalyticsShim] Already configured, skipping");
    return;
  }

  NSLog(@"[VortexFirebaseAnalyticsShim] Configuring Firebase Analytics");

  // Configure Firebase with default options from GoogleService-Info.plist
  if ([FIRApp defaultApp] == nil) {
    [FIRApp configure];
  }

#if DEBUG
  // Enable debug mode for Firebase Analytics in debug builds
  NSLog(@"[VortexFirebaseAnalyticsShim] Debug mode enabled");
#endif

  gConfigured = YES;
  NSLog(@"[VortexFirebaseAnalyticsShim] Firebase Analytics configured successfully");
}

#pragma mark - User Identity

+ (void)setUserId:(NSString *_Nullable)userId {
  if (!gConfigured) {
    NSLog(@"[VortexFirebaseAnalyticsShim] WARNING: setUserId called before configure");
  }

  [FIRAnalytics setUserID:userId];
  NSLog(@"[VortexFirebaseAnalyticsShim] User ID set to: %@", userId ?: @"<nil>");
}

#pragma mark - Event Logging

+ (void)logEvent:(NSString *)event
      parameters:(NSDictionary<NSString *, id> *_Nullable)parameters {
  if (!event.length) {
    NSLog(@"[VortexFirebaseAnalyticsShim] ERROR: event name is required");
    return;
  }

  if (!gConfigured) {
    NSLog(@"[VortexFirebaseAnalyticsShim] WARNING: logEvent called before configure: %@", event);
  }

  [FIRAnalytics logEventWithName:event parameters:parameters];

#if DEBUG
  NSLog(@"[VortexFirebaseAnalyticsShim] Logged event: %@ params: %@", event, parameters);
#endif
}

+ (void)logScreenView:(NSString *)screenName
          screenClass:(NSString *_Nullable)screenClass {
  if (!screenName.length) {
    NSLog(@"[VortexFirebaseAnalyticsShim] ERROR: screenName is required");
    return;
  }

  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  params[kFIRParameterScreenName] = screenName;
  if (screenClass.length) {
    params[kFIRParameterScreenClass] = screenClass;
  }

  [FIRAnalytics logEventWithName:kFIREventScreenView parameters:params];

#if DEBUG
  NSLog(@"[VortexFirebaseAnalyticsShim] Logged screen view: %@ class: %@",
        screenName, screenClass ?: @"<none>");
#endif
}

#pragma mark - User Properties

+ (void)setUserPropertyString:(NSString *_Nullable)value
                      forName:(NSString *)name {
  if (!name.length) {
    NSLog(@"[VortexFirebaseAnalyticsShim] ERROR: property name is required");
    return;
  }

  if (!gConfigured) {
    NSLog(@"[VortexFirebaseAnalyticsShim] WARNING: setUserProperty called before configure");
  }

  [FIRAnalytics setUserPropertyString:value forName:name];

#if DEBUG
  NSLog(@"[VortexFirebaseAnalyticsShim] Set user property: %@ = %@", name, value ?: @"<nil>");
#endif
}

#pragma mark - Analytics Control

+ (void)setAnalyticsCollectionEnabled:(BOOL)enabled {
  [FIRAnalytics setAnalyticsCollectionEnabled:enabled];
  NSLog(@"[VortexFirebaseAnalyticsShim] Analytics collection %@",
        enabled ? @"enabled" : @"disabled");
}

+ (void)reset {
  // Clear user ID
  [FIRAnalytics setUserID:nil];

  // Note: Firebase doesn't have a direct "reset" like Mixpanel.
  // User properties would need to be cleared individually if needed.
  NSLog(@"[VortexFirebaseAnalyticsShim] Reset - cleared user ID");
}

@end

NS_ASSUME_NONNULL_END
