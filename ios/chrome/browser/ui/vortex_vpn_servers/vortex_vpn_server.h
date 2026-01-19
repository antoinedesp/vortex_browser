// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVER_H_
#define IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVER_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Model object representing a VPN server from the Vortex API.
@interface VortexVPNServer : NSObject

// Server ID from the API.
@property(nonatomic, assign) NSInteger serverId;

// Unique identifier for the server.
@property(nonatomic, copy) NSString* uuid;

// Server IP address.
@property(nonatomic, copy) NSString* ip;

// Server port (0 means default).
@property(nonatomic, assign) NSInteger port;

// Username for authentication.
@property(nonatomic, copy) NSString* username;

// Password for authentication.
@property(nonatomic, copy) NSString* password;

// Whether the server is currently online.
@property(nonatomic, assign) BOOL isOnline;

// Whether this is a premium server.
@property(nonatomic, assign) BOOL isPremium;

// Country code (e.g., "nl", "us").
@property(nonatomic, copy) NSString* country;

// Pre-shared key for IKEv2.
@property(nonatomic, copy) NSString* psk;

// OpenVPN configuration file content (.ovpn format).
// This is the complete configuration file provided by the API for OpenVPN connections.
@property(nonatomic, copy, nullable) NSString* ovpnConfig;

// Optional flag URL/emoji.
@property(nonatomic, copy) NSString* flag;

// Creates a VortexVPNServer from an API response dictionary.
+ (nullable instancetype)serverFromDictionary:(NSDictionary*)dict;

// Returns the display name for the server's country.
- (NSString*)countryDisplayName;

@end

NS_ASSUME_NONNULL_END

#endif  // IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVER_H_
