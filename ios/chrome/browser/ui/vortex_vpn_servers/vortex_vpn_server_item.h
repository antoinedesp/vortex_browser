// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVER_ITEM_H_
#define IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVER_ITEM_H_

#import <Foundation/Foundation.h>

@class VortexVPNServer;

NS_ASSUME_NONNULL_BEGIN

// Display model for VPN server table cells.
@interface VortexVPNServerItem : NSObject

// The display title (country name).
@property(nonatomic, copy) NSString* title;

// The subtitle (server IP or status).
@property(nonatomic, copy, nullable) NSString* subtitle;

// Whether the server is online.
@property(nonatomic, assign) BOOL isOnline;

// Whether this is a premium server.
@property(nonatomic, assign) BOOL isPremium;

// Whether this item is currently selected.
@property(nonatomic, assign) BOOL isSelected;

// Whether this item is enabled for selection.
@property(nonatomic, assign) BOOL isEnabled;

// Country code for flag display.
@property(nonatomic, copy, nullable) NSString* countryCode;

// The underlying server model (nil for "Auto" option).
@property(nonatomic, strong, nullable) VortexVPNServer* server;

// Whether this is the "Auto (Best Server)" option.
@property(nonatomic, assign) BOOL isAutoOption;

// Creates an item for the "Auto (Best Server)" option.
+ (instancetype)autoOptionItemWithSelected:(BOOL)selected;

// Creates an item from a VortexVPNServer.
+ (instancetype)itemWithServer:(VortexVPNServer*)server
                      selected:(BOOL)selected
                       enabled:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END

#endif  // IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVER_ITEM_H_
