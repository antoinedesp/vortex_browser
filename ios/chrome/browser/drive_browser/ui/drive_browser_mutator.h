// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_DRIVE_BROWSER_MUTATOR_H_
#define IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_DRIVE_BROWSER_MUTATOR_H_

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ActiveDownloadItem;
@class DriveBrowserItem;

/// Mutator protocol for the drive browser.
/// Handles user interactions from the drive browser UI.
@protocol DriveBrowserMutator <NSObject>

/// Called when the user selects an item to preview.
/// @param item The selected item.
- (void)userDidSelectItem:(DriveBrowserItem*)item;

/// Called when the user requests to delete an item.
/// @param item The item to delete.
- (void)userDidDeleteItem:(DriveBrowserItem*)item;

/// Called when the user requests to share an item.
/// @param item The item to share.
/// @param sourceView The view to anchor the share sheet to.
- (void)userDidShareItem:(DriveBrowserItem*)item sourceView:(UIView*)sourceView;

/// Called when the user requests to open an item in the Files app.
/// @param item The item to open in Files.
- (void)userDidOpenInFilesApp:(DriveBrowserItem*)item;

/// Called when the user triggers a refresh (pull-to-refresh).
- (void)userDidRefresh;

@optional

/// Called when the user requests to cancel an active download.
/// @param item The download item to cancel.
- (void)userDidCancelDownload:(ActiveDownloadItem*)item;

/// Called when the user requests to retry a failed download.
/// @param item The download item to retry.
- (void)userDidRetryDownload:(ActiveDownloadItem*)item;

@end

#endif  // IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_DRIVE_BROWSER_MUTATOR_H_
