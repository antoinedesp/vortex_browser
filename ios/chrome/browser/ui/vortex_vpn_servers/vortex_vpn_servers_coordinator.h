// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVERS_COORDINATOR_H_
#define IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVERS_COORDINATOR_H_

#import "ios/chrome/browser/shared/coordinator/chrome_coordinator/chrome_coordinator.h"

@protocol VortexVPNServersCoordinatorDelegate;

// Coordinator for the VPN server selection UI.
@interface VortexVPNServersCoordinator : ChromeCoordinator

// Delegate for coordinator events.
@property(nonatomic, weak) id<VortexVPNServersCoordinatorDelegate> delegate;

@end

// Delegate protocol for VortexVPNServersCoordinator events.
@protocol VortexVPNServersCoordinatorDelegate <NSObject>

// Called when the coordinator should be dismissed.
- (void)vortexVPNServersCoordinatorDidRequestDismissal:
    (VortexVPNServersCoordinator*)coordinator;

@end

#endif  // IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVERS_COORDINATOR_H_
