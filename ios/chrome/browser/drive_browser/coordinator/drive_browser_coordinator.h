// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_DRIVE_BROWSER_COORDINATOR_DRIVE_BROWSER_COORDINATOR_H_
#define IOS_CHROME_BROWSER_DRIVE_BROWSER_COORDINATOR_DRIVE_BROWSER_COORDINATOR_H_

#import "ios/chrome/browser/shared/coordinator/chrome_coordinator/chrome_coordinator.h"

/// Coordinator for the drive browser feature.
/// Manages the presentation of the drive browser modal and coordinates
/// between the mediator, view controller, and file preview.
@interface DriveBrowserCoordinator : ChromeCoordinator

@end

#endif  // IOS_CHROME_BROWSER_DRIVE_BROWSER_COORDINATOR_DRIVE_BROWSER_COORDINATOR_H_
