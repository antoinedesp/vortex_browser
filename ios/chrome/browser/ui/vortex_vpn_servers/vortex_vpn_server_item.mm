// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_server_item.h"

#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_server.h"
#import "ios/chrome/grit/ios_strings.h"
#import "ui/base/l10n/l10n_util.h"

@implementation VortexVPNServerItem

+ (instancetype)autoOptionItemWithSelected:(BOOL)selected {
  VortexVPNServerItem* item = [[VortexVPNServerItem alloc] init];
  item.title = l10n_util::GetNSString(IDS_IOS_VPN_SERVERS_AUTO);
  item.subtitle = l10n_util::GetNSString(IDS_IOS_VPN_SERVERS_AUTO_SUBTITLE);
  item.isOnline = YES;
  item.isPremium = NO;
  item.isSelected = selected;
  item.isEnabled = YES;
  item.countryCode = nil;
  item.server = nil;
  item.isAutoOption = YES;
  return item;
}

+ (instancetype)itemWithServer:(VortexVPNServer*)server
                      selected:(BOOL)selected
                       enabled:(BOOL)enabled {
  VortexVPNServerItem* item = [[VortexVPNServerItem alloc] init];
  item.title = [server countryDisplayName];
  item.subtitle = server.ip;
  item.isOnline = server.isOnline;
  item.isPremium = server.isPremium;
  item.isSelected = selected;
  item.isEnabled = enabled && server.isOnline;
  item.countryCode = server.country;
  item.server = server;
  item.isAutoOption = NO;
  return item;
}

@end
