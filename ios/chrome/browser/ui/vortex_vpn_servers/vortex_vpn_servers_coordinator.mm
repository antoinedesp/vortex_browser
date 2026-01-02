// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_servers_coordinator.h"

#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_servers_mediator.h"
#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_servers_view_controller.h"

@interface VortexVPNServersCoordinator () <VortexVPNServersMediatorDelegate,
                                           VortexVPNServersViewControllerDelegate>
@property(nonatomic, strong) VortexVPNServersViewController* viewController;
@property(nonatomic, strong) VortexVPNServersMediator* mediator;
@property(nonatomic, strong) UINavigationController* navigationController;
@end

@implementation VortexVPNServersCoordinator

#pragma mark - ChromeCoordinator

- (void)start {
  // Create view controller
  self.viewController = [[VortexVPNServersViewController alloc]
      initWithStyle:UITableViewStyleInsetGrouped];
  self.viewController.delegate = self;

  // Create mediator
  self.mediator = [[VortexVPNServersMediator alloc] init];
  self.mediator.delegate = self;
  self.mediator.consumer = self.viewController;

  // Wire up mutator
  self.viewController.mutator = self.mediator;

  // Create navigation controller
  self.navigationController = [[UINavigationController alloc]
      initWithRootViewController:self.viewController];
  self.navigationController.modalPresentationStyle =
      UIModalPresentationFormSheet;

  // Present
  [self.baseViewController presentViewController:self.navigationController
                                        animated:YES
                                      completion:nil];

  // Start loading servers
  [self.mediator fetchServers];
}

- (void)stop {
  [self.mediator disconnect];
  self.mediator = nil;
  self.viewController = nil;

  [self.navigationController.presentingViewController
      dismissViewControllerAnimated:YES
                         completion:nil];
  self.navigationController = nil;
}

#pragma mark - VortexVPNServersMediatorDelegate

- (void)mediatorDidSelectServer:(VortexVPNServersMediator*)mediator {
  // Server selected - could auto-dismiss here or let user dismiss manually
  // For now, we let the user see the selection and dismiss manually
}

#pragma mark - VortexVPNServersViewControllerDelegate

- (void)viewControllerDidRequestDismissal:
    (VortexVPNServersViewController*)viewController {
  [self.delegate vortexVPNServersCoordinatorDidRequestDismissal:self];
}

@end
