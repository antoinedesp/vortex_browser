// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVERS_MUTATOR_H_
#define IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVERS_MUTATOR_H_

#import <Foundation/Foundation.h>

@class VortexVPNServerItem;

// Protocol for mutating VPN server selection state.
@protocol VortexVPNServersMutator <NSObject>

// Called when the user selects a server item.
- (void)didSelectServerItem:(VortexVPNServerItem*)item;

// Called when the user taps the retry button after an error.
- (void)didRequestRetry;

@end

#endif  // IOS_CHROME_BROWSER_UI_VORTEX_VPN_SERVERS_VORTEX_VPN_SERVERS_MUTATOR_H_
