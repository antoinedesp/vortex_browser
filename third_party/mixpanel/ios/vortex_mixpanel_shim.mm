// Copyright 2025 Vortex Softwares Ltd
// Use of this source code is prohibited

#import "third_party/mixpanel/ios/vortex_mixpanel_shim.h"

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import <Mixpanel/Mixpanel.h>

NS_ASSUME_NONNULL_BEGIN

#define HAS_MIXPANEL 1

@implementation VortexMixpanelShim

static BOOL gInitialized = NO;
static NSString *gToken = nil;
static NSString *gUserId = nil;

#pragma mark - Configuration

+ (void)configureWithToken:(NSString *)token
                    userId:(NSString * _Nullable)userId {
  if (!token.length) {
    NSLog(@"[VortexMixpanelShim] ERROR: token is required");
    return;
  }

  BOOL tokenChanged = ![gToken isEqualToString:token];
  BOOL userChanged = (gUserId != userId) && ![gUserId isEqualToString:userId];

  gToken = [token copy];
  gUserId = [userId copy];

#if HAS_MIXPANEL
  if (gInitialized && !tokenChanged) {
    if (userChanged) {
      [self identifyUserWithId:gUserId];
    }
    return;
  }

  NSLog(@"[VortexMixpanelShim] Initializing Mixpanel (ObjC) with token: %@ user: %@",
        gToken, gUserId ?: @"<anonymous>");

  // ObjC SDK API
  [Mixpanel sharedInstanceWithToken:gToken];
#if DEBUG
  [Mixpanel sharedInstance].enableLogging = YES;
#endif

  if (gUserId.length > 0) {
    [[Mixpanel sharedInstance] identify:gUserId];
  }

  gInitialized = YES;
#else
  NSLog(@"[VortexMixpanelShim] HAS_MIXPANEL=0 -> stub");
#endif
}

+ (void)identifyUserWithId:(NSString * _Nullable)userId {
  gUserId = [userId copy];

#if HAS_MIXPANEL
  if (!gInitialized) {
    NSLog(@"[VortexMixpanelShim] identifyUserWithId before configure");
    return;
  }

  Mixpanel *mixpanel = [Mixpanel sharedInstance];

  if (!gUserId.length) {
    [mixpanel reset];
    NSLog(@"[VortexMixpanelShim] Mixpanel identity reset");
    return;
  }

  [mixpanel identify:gUserId];
  NSLog(@"[VortexMixpanelShim] identify -> %@", gUserId);
#else
  NSLog(@"[VortexMixpanelShim] Stub identify: %@", userId ?: @"<nil>");
#endif
}

#pragma mark - Events

+ (void)trackEvent:(NSString *)event
        properties:(NSDictionary<NSString *, id> * _Nullable)properties {
  if (!event.length) {
    NSLog(@"[VortexMixpanelShim] ERROR: event name required");
    return;
  }

#if HAS_MIXPANEL
  if (!gInitialized) {
    NSLog(@"[VortexMixpanelShim] WARNING: trackEvent before configure: %@", event);
  }
  Mixpanel *mixpanel = [Mixpanel sharedInstance];
  if (properties.count) {
    [mixpanel track:event properties:properties];
  } else {
    [mixpanel track:event];
  }
#else
  NSLog(@"[VortexMixpanelShim] Stub track: %@ props=%@", event, properties);
#endif
}

+ (void)trackScreen:(NSString *)screenName
         properties:(NSDictionary<NSString *, id> * _Nullable)properties {
  if (!screenName.length) {
    NSLog(@"[VortexMixpanelShim] ERROR: screenName required");
    return;
  }
  NSMutableDictionary *merged =
      properties ? [properties mutableCopy] : [NSMutableDictionary dictionary];
  merged[@"$screen_name"] = screenName;

  [self trackEvent:@"Screen View" properties:merged];
}

#pragma mark - User properties

+ (void)setUserProperty:(NSString *)key
                  value:(id _Nullable)value {
  if (!key.length) {
    NSLog(@"[VortexMixpanelShim] ERROR: property key required");
    return;
  }

#if HAS_MIXPANEL
  MixpanelPeople *people = [Mixpanel sharedInstance].people;
  if (value) {
    [people set:key to:value];
  } else {
    [people unset:@[ key ]];
  }
#else
  NSLog(@"[VortexMixpanelShim] Stub setUserProperty: %@ = %@", key, value);
#endif
}

+ (void)setUserProperties:(NSDictionary<NSString *, id> * _Nullable)properties {
  if (!properties.count) return;

#if HAS_MIXPANEL
  [[Mixpanel sharedInstance].people set:properties];
#else
  NSLog(@"[VortexMixpanelShim] Stub setUserProperties: %@", properties);
#endif
}

#pragma mark - Flush / reset

+ (void)flush {
#if HAS_MIXPANEL
  [[Mixpanel sharedInstance] flush];
#else
  NSLog(@"[VortexMixpanelShim] Stub flush");
#endif
}

+ (void)reset {
#if HAS_MIXPANEL
  [[Mixpanel sharedInstance] reset];
  gUserId = nil;
  NSLog(@"[VortexMixpanelShim] Mixpanel reset");
#else
  NSLog(@"[VortexMixpanelShim] Stub reset");
#endif
}

@end

NS_ASSUME_NONNULL_END
