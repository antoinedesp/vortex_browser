// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_servers_mediator.h"

#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_server.h"
#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_server_item.h"
#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_servers_consumer.h"
#import "ios/chrome/browser/vortex_plus/vortex_plus_manager.h"
#import "ios/chrome/browser/vortex_vpn/vortex_vpn_manager.h"
#import "ios/chrome/grit/ios_strings.h"
#import "ui/base/l10n/l10n_util.h"

@interface VortexVPNServersMediator ()
@property(nonatomic, strong) NSArray<VortexVPNServer*>* servers;
@end

@implementation VortexVPNServersMediator

- (void)fetchServers {
  [self.consumer showLoading];

  __weak __typeof(self) weakSelf = self;
  [[VortexVPNManager sharedManager]
      fetchAllServersWithCompletion:^(NSArray<VortexVPNServer*>* servers,
                                      NSError* error) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }

        if (error) {
          NSString* errorMessage =
              l10n_util::GetNSString(IDS_IOS_VPN_SERVERS_ERROR_FETCH);
          [strongSelf.consumer showError:errorMessage];
          return;
        }

        strongSelf.servers = servers;
        [strongSelf updateConsumerWithServers];
      }];
}

- (void)updateConsumerWithServers {
  VortexVPNServer* selectedServer =
      [VortexVPNManager sharedManager].selectedServer;
  BOOL isPremium = [[VortexPlusManager sharedManager] isPremium];

  NSMutableArray<VortexVPNServerItem*>* items = [NSMutableArray array];

  // Add "Auto (Best Server)" option first
  BOOL autoSelected = (selectedServer == nil);
  VortexVPNServerItem* autoItem =
      [VortexVPNServerItem autoOptionItemWithSelected:autoSelected];
  [items addObject:autoItem];

  // Add server items
  for (VortexVPNServer* server in self.servers) {
    BOOL isSelected = NO;
    if (selectedServer && server.uuid) {
      isSelected = [selectedServer.uuid isEqualToString:server.uuid];
    }

    // Premium servers are enabled only for premium users
    BOOL enabled = server.isOnline && (!server.isPremium || isPremium);

    VortexVPNServerItem* item = [VortexVPNServerItem itemWithServer:server
                                                           selected:isSelected
                                                            enabled:enabled];
    [items addObject:item];
  }

  [self.consumer showServers:[items copy]];
}

- (void)disconnect {
  self.consumer = nil;
  self.delegate = nil;
  self.servers = nil;
}

#pragma mark - VortexVPNServersMutator

- (void)didSelectServerItem:(VortexVPNServerItem*)item {
  if (!item.isEnabled) {
    // Premium server selected by non-premium user - could show upgrade prompt
    return;
  }

  if (item.isAutoOption) {
    [[VortexVPNManager sharedManager] clearSelectedServer];
  } else {
    [[VortexVPNManager sharedManager] setSelectedServer:item.server];
  }

  // Update the UI with new selection
  [self updateConsumerWithServers];

  // Notify delegate
  [self.delegate mediatorDidSelectServer:self];
}

- (void)didRequestRetry {
  [self fetchServers];
}

@end
