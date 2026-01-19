// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_server.h"

@implementation VortexVPNServer

+ (nullable instancetype)serverFromDictionary:(NSDictionary*)dict {
  if (![dict isKindOfClass:[NSDictionary class]]) {
    return nil;
  }

  VortexVPNServer* server = [[VortexVPNServer alloc] init];

  // Parse required fields
  id serverId = dict[@"id"];
  if ([serverId respondsToSelector:@selector(integerValue)]) {
    server.serverId = [serverId integerValue];
  }

  id uuid = dict[@"uuid"];
  if ([uuid isKindOfClass:[NSString class]]) {
    server.uuid = uuid;
  }

  id ip = dict[@"ip"];
  if ([ip isKindOfClass:[NSString class]]) {
    server.ip = ip;
  } else {
    // IP is required
    return nil;
  }

  id port = dict[@"port"];
  if ([port respondsToSelector:@selector(integerValue)]) {
    server.port = [port integerValue];
  }

  id username = dict[@"username"];
  if ([username isKindOfClass:[NSString class]]) {
    server.username = username;
  }

  id password = dict[@"password"];
  if ([password isKindOfClass:[NSString class]]) {
    server.password = password;
  }

  id isOnline = dict[@"is_online"];
  if ([isOnline respondsToSelector:@selector(boolValue)]) {
    server.isOnline = [isOnline boolValue];
  }

  id isPremium = dict[@"is_premium"];
  if ([isPremium respondsToSelector:@selector(boolValue)]) {
    server.isPremium = [isPremium boolValue];
  }

  id country = dict[@"country"];
  if ([country isKindOfClass:[NSString class]]) {
    server.country = country;
  }

  id psk = dict[@"psk"];
  if ([psk isKindOfClass:[NSString class]]) {
    server.psk = psk;
  }

  // Parse OpenVPN configuration if available
  id ovpnConfig = dict[@"ovpn_config"];
  if ([ovpnConfig isKindOfClass:[NSString class]]) {
    server.ovpnConfig = ovpnConfig;
  }

  // Either PSK (for IKEv2) or ovpn_config (for OpenVPN) must be present
  if (!server.psk && !server.ovpnConfig) {
    return nil;
  }

  id flag = dict[@"flag"];
  if ([flag isKindOfClass:[NSString class]]) {
    server.flag = flag;
  }

  return server;
}

- (NSString*)countryDisplayName {
  if (!self.country || self.country.length == 0) {
    return @"Unknown";
  }

  // Map country codes to display names
  static NSDictionary<NSString*, NSString*>* countryNames = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    countryNames = @{
      @"us" : @"United States",
      @"nl" : @"Netherlands",
      @"de" : @"Germany",
      @"gb" : @"United Kingdom",
      @"uk" : @"United Kingdom",
      @"fr" : @"France",
      @"ca" : @"Canada",
      @"au" : @"Australia",
      @"jp" : @"Japan",
      @"sg" : @"Singapore",
      @"ch" : @"Switzerland",
      @"se" : @"Sweden",
      @"no" : @"Norway",
      @"dk" : @"Denmark",
      @"fi" : @"Finland",
      @"it" : @"Italy",
      @"es" : @"Spain",
      @"br" : @"Brazil",
      @"mx" : @"Mexico",
      @"in" : @"India",
      @"kr" : @"South Korea",
      @"hk" : @"Hong Kong",
      @"ie" : @"Ireland",
      @"at" : @"Austria",
      @"be" : @"Belgium",
      @"pl" : @"Poland",
      @"cz" : @"Czech Republic",
      @"nz" : @"New Zealand",
      @"za" : @"South Africa",
    };
  });

  NSString* displayName = countryNames[self.country.lowercaseString];
  return displayName ?: self.country.uppercaseString;
}

@end
