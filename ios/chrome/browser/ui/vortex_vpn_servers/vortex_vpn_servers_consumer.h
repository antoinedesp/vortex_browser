// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVERS_CONSUMER_H_
#define IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVERS_CONSUMER_H_

#import <Foundation/Foundation.h>

@class VortexVPNServer;
@class VortexVPNServerItem;

// Protocol for receiving VPN server updates from the mediator.
@protocol VortexVPNServersConsumer <NSObject>

// Called to show a loading indicator while fetching servers.
- (void)showLoading;

// Called when there's an error loading servers.
- (void)showError:(NSString*)message;

// Called when servers have been successfully loaded.
- (void)showServers:(NSArray<VortexVPNServerItem*>*)servers;

// Called when the selected server has been updated.
- (void)updateSelectedServer:(VortexVPNServer*)server;

@end

#endif  // IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVERS_CONSUMER_H_
