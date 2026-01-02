// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_ACTIVE_DOWNLOAD_CELL_H_
#define IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_ACTIVE_DOWNLOAD_CELL_H_

#import <UIKit/UIKit.h>

@class ActiveDownloadItem;

/// Reuse identifier for ActiveDownloadCell.
extern NSString* const kActiveDownloadCellReuseIdentifier;

/// Table view cell for displaying an active download with progress.
@interface ActiveDownloadCell : UITableViewCell

/// Configures the cell with the given download item.
/// @param item The active download item to display.
- (void)configureWithItem:(ActiveDownloadItem*)item;

/// Updates the progress bar to the given value.
/// @param progress Progress value from 0.0 to 1.0.
- (void)updateProgress:(float)progress;

/// Updates the progress text (e.g., "45 MB / 100 MB").
/// @param progressText The progress text to display.
- (void)updateProgressText:(NSString*)progressText;

/// Block called when the cancel button is tapped.
@property(nonatomic, copy) void (^cancelHandler)(void);

@end

#endif  // IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_ACTIVE_DOWNLOAD_CELL_H_
