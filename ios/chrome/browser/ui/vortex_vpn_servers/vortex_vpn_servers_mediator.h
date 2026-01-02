// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVERS_MEDIATOR_H_
#define IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVERS_MEDIATOR_H_

#import <Foundation/Foundation.h>

#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_servers_mutator.h"

@protocol VortexVPNServersConsumer;
@protocol VortexVPNServersMediatorDelegate;

// Mediator for the VPN server selection UI.
@interface VortexVPNServersMediator : NSObject <VortexVPNServersMutator>

// The consumer to receive UI updates.
@property(nonatomic, weak) id<VortexVPNServersConsumer> consumer;

// Delegate for mediator events.
@property(nonatomic, weak) id<VortexVPNServersMediatorDelegate> delegate;

// Starts fetching the server list.
- (void)fetchServers;

// Disconnects the mediator and cleans up.
- (void)disconnect;

@end

// Delegate protocol for VortexVPNServersMediator events.
@protocol VortexVPNServersMediatorDelegate <NSObject>

// Called when the user has selected a server and the selection is complete.
- (void)mediatorDidSelectServer:(VortexVPNServersMediator*)mediator;

@end

#endif  // IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVERS_MEDIATOR_H_
