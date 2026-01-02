// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVERS_VIEW_CONTROLLER_H_
#define IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVERS_VIEW_CONTROLLER_H_

#import <UIKit/UIKit.h>

#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_servers_consumer.h"

@protocol VortexVPNServersMutator;
@protocol VortexVPNServersViewControllerDelegate;

// View controller displaying a list of VPN servers for selection.
@interface VortexVPNServersViewController
    : UITableViewController <VortexVPNServersConsumer>

// The mutator to handle user actions.
@property(nonatomic, weak) id<VortexVPNServersMutator> mutator;

// Delegate for view controller events.
@property(nonatomic, weak) id<VortexVPNServersViewControllerDelegate> delegate;

@end

// Delegate protocol for VortexVPNServersViewController events.
@protocol VortexVPNServersViewControllerDelegate <NSObject>

// Called when the user taps the Done button.
- (void)viewControllerDidRequestDismissal:
    (VortexVPNServersViewController*)viewController;

@end

#endif  // IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVERS_VIEW_CONTROLLER_H_
