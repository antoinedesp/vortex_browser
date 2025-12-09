// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_APP_NETWORK_EXTENSION_PACKET_TUNNEL_PROVIDER_H_
#define IOS_CHROME_APP_NETWORK_EXTENSION_PACKET_TUNNEL_PROVIDER_H_

#import <NetworkExtension/NetworkExtension.h>

// VortexVPN packet tunnel provider for IKEv2 VPN connections.
@interface VortexPacketTunnelProvider : NEPacketTunnelProvider

@end

#endif  // IOS_CHROME_APP_NETWORK_EXTENSION_PACKET_TUNNEL_PROVIDER_H_