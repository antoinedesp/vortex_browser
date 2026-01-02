// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_DRIVE_BROWSER_CONSUMER_H_
#define IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_DRIVE_BROWSER_CONSUMER_H_

#import <Foundation/Foundation.h>

@class ActiveDownloadItem;
@class DriveBrowserItem;

/// Consumer protocol for the drive browser UI.
/// This protocol should only be implemented by UIViewController subclasses.
@protocol DriveBrowserConsumer <NSObject>

/// Updates the drive browser with new items.
/// @param items The array of DriveBrowserItem objects to display.
- (void)setItems:(NSArray<DriveBrowserItem*>*)items;

/// Shows or hides the loading state.
/// @param loading YES to show loading indicator, NO to hide it.
- (void)setLoadingState:(BOOL)loading;

/// Shows or hides the empty state when no files exist.
/// @param empty YES to show empty state, NO to hide it.
- (void)setEmptyState:(BOOL)empty;

/// Removes an item at the specified index from the UI.
/// @param index The index of the item to remove.
- (void)removeItemAtIndex:(NSUInteger)index;

@optional

/// Updates the drive browser with active downloads.
/// @param downloads The array of ActiveDownloadItem objects to display.
- (void)setActiveDownloads:(NSArray<ActiveDownloadItem*>*)downloads;

/// Updates the progress of a specific download.
/// @param identifier The unique identifier of the download.
/// @param progress The progress value from 0.0 to 1.0.
/// @param bytesReceived The number of bytes received.
/// @param totalBytes The total expected bytes.
- (void)updateDownloadProgress:(NSString*)identifier
                      progress:(float)progress
                 bytesReceived:(int64_t)bytesReceived
                    totalBytes:(int64_t)totalBytes;

/// Updates the state of a specific download.
/// @param identifier The unique identifier of the download.
/// @param state The new state of the download.
- (void)updateDownloadState:(NSString*)identifier
                      state:(NSInteger)state;

/// Removes an active download from the UI after completion.
/// @param identifier The unique identifier of the download to remove.
- (void)removeActiveDownload:(NSString*)identifier;

@end

#endif  // IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_DRIVE_BROWSER_CONSUMER_H_
