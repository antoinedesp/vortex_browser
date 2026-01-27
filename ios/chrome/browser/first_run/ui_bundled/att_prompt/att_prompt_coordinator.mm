// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/first_run/ui_bundled/att_prompt/att_prompt_coordinator.h"

#import <AppTrackingTransparency/AppTrackingTransparency.h>

#import "ios/chrome/browser/first_run/ui_bundled/att_prompt/att_prompt_view_controller.h"
#import "ios/chrome/browser/first_run/ui_bundled/first_run_screen_delegate.h"

@implementation ATTPromptCoordinator {
  // ATT prompt view controller.
  ATTPromptViewController* _viewController;
  // Delegate for first run screen navigation.
  __weak id<FirstRunScreenDelegate> _delegate;
}

@synthesize baseNavigationController = _baseNavigationController;

- (instancetype)initWithBaseNavigationController:
                    (UINavigationController*)navigationController
                                         browser:(Browser*)browser
                                        delegate:
                                            (id<FirstRunScreenDelegate>)delegate {
  if ((self = [super initWithBaseViewController:navigationController
                                        browser:browser])) {
    _baseNavigationController = navigationController;
    _delegate = delegate;
  }
  return self;
}

#pragma mark - ChromeCoordinator

- (void)start {
  [super start];
  _viewController = [[ATTPromptViewController alloc] init];
  _viewController.delegate = self;
  _viewController.modalInPresentation = YES;

  BOOL animated = self.baseNavigationController.topViewController != nil;
  [self.baseNavigationController setViewControllers:@[ _viewController ]
                                           animated:animated];
}

- (void)stop {
  _viewController.delegate = nil;
  _viewController = nil;
  _delegate = nil;
  [super stop];
}

#pragma mark - PromoStyleViewControllerDelegate

- (void)didTapPrimaryActionButton {
  [self requestTrackingAuthorizationAndFinish];
}

- (void)didTapSecondaryActionButton {
  [self finishPresenting];
}

#pragma mark - Private

// Requests App Tracking Transparency authorization and finishes presenting.
- (void)requestTrackingAuthorizationAndFinish {
  __weak __typeof(self) weakSelf = self;
  if (@available(iOS 14, *)) {
    // Check if we can request tracking authorization.
    ATTrackingManagerAuthorizationStatus status =
        ATTrackingManager.trackingAuthorizationStatus;
    if (status == ATTrackingManagerAuthorizationStatusNotDetermined) {
      [ATTrackingManager
          requestTrackingAuthorizationWithCompletionHandler:^(
              ATTrackingManagerAuthorizationStatus newStatus) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [weakSelf finishPresenting];
            });
          }];
      return;
    }
  }
  // If iOS < 14 or status already determined, just finish.
  [self finishPresenting];
}

- (void)finishPresenting {
  [_delegate screenWillFinishPresenting];
}

@end
