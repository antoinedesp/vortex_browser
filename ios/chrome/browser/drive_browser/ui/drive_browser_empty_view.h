// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_DRIVE_BROWSER_EMPTY_VIEW_H_
#define IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_DRIVE_BROWSER_EMPTY_VIEW_H_

#import <UIKit/UIKit.h>

/// Empty state view for the drive browser when no files are available.
@interface DriveBrowserEmptyView : UIView

/// Initializes the empty view with a frame.
- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCoder:(NSCoder*)coder NS_UNAVAILABLE;

@end

#endif  // IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_DRIVE_BROWSER_EMPTY_VIEW_H_
