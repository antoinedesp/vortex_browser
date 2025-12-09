// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/app/network_extension/packet_tunnel_provider.h"

#import <NetworkExtension/NetworkExtension.h>

@implementation VortexPacketTunnelProvider

- (void)startTunnelWithOptions:(NSDictionary<NSString*, NSObject*>*)options
             completionHandler:(void (^)(NSError* _Nullable error))completionHandler {
  NSLog(@"🔵 VORTEX VPN: Starting tunnel");
  
  // Configure IKEv2 settings
  NEPacketTunnelNetworkSettings* settings = 
      [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"vpn.vortex.com"];
  
  // Set IPv4 settings
  NEIPv4Settings* ipv4Settings = [[NEIPv4Settings alloc] 
      initWithAddresses:@[@"10.0.0.2"]
           subnetMasks:@[@"255.255.255.0"]];
  settings.IPv4Settings = ipv4Settings;
  
  // Set DNS settings
  NEDNSSettings* dnsSettings = [[NEDNSSettings alloc] 
      initWithServers:@[@"8.8.8.8", @"8.8.4.4"]];
  settings.DNSSettings = dnsSettings;
  
  // Apply settings
  [self setTunnelNetworkSettings:settings completionHandler:^(NSError* error) {
    if (error) {
      NSLog(@"🔴 VORTEX VPN: Failed to set tunnel settings: %@", error);
      completionHandler(error);
      return;
    }
    
    NSLog(@"🟢 VORTEX VPN: Tunnel started successfully");
    completionHandler(nil);
  }];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason
           completionHandler:(void (^)(void))completionHandler {
  NSLog(@"🔵 VORTEX VPN: Stopping tunnel, reason: %ld", (long)reason);
  completionHandler();
}

- (void)handleAppMessage:(NSData*)messageData
       completionHandler:(void (^)(NSData* _Nullable responseData))completionHandler {
  NSLog(@"🔵 VORTEX VPN: Received app message");
  // Handle messages from the main app
  completionHandler(nil);
}

@end