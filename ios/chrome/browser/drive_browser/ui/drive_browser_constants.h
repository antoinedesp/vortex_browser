// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_DRIVE_BROWSER_CONSTANTS_H_
#define IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_DRIVE_BROWSER_CONSTANTS_H_

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// Accessibility identifier for the drive browser view controller.
extern NSString* const kDriveBrowserViewControllerAccessibilityId;

/// Accessibility identifier for the drive browser table view.
extern NSString* const kDriveBrowserTableViewAccessibilityId;

/// Accessibility identifier for the drive browser close button.
extern NSString* const kDriveBrowserCloseButtonAccessibilityId;

/// Accessibility identifier for the drive browser empty view.
extern NSString* const kDriveBrowserEmptyViewAccessibilityId;

/// Accessibility identifier prefix for drive browser item cells.
extern NSString* const kDriveBrowserItemCellAccessibilityIdPrefix;

/// Cell reuse identifier for drive browser item cells.
extern NSString* const kDriveBrowserItemCellReuseId;

/// Layout constants for the drive browser UI.
extern const CGFloat kDriveBrowserItemCellHeight;
extern const CGFloat kDriveBrowserItemIconSize;
extern const CGFloat kDriveBrowserItemPadding;

#endif  // IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_DRIVE_BROWSER_CONSTANTS_H_
