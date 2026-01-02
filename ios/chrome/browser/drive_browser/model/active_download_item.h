// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_DRIVE_BROWSER_MODEL_ACTIVE_DOWNLOAD_ITEM_H_
#define IOS_CHROME_BROWSER_DRIVE_BROWSER_MODEL_ACTIVE_DOWNLOAD_ITEM_H_

#import <Foundation/Foundation.h>

/// Represents the state of an active download.
typedef NS_ENUM(NSInteger, ActiveDownloadState) {
  ActiveDownloadStateInProgress,
  ActiveDownloadStateComplete,
  ActiveDownloadStateFailed,
  ActiveDownloadStateCancelled,
};

/// Represents the type of content being downloaded.
typedef NS_ENUM(NSInteger, ActiveDownloadType) {
  ActiveDownloadTypeImage,
  ActiveDownloadTypeVideo,
  ActiveDownloadTypeFile,
};

/// Notification name posted when a new download is added.
extern NSString* const kActiveDownloadAddedNotification;

/// Notification name posted when a download is updated (progress/state change).
extern NSString* const kActiveDownloadUpdatedNotification;

/// Represents an in-progress download with progress tracking.
@interface ActiveDownloadItem : NSObject

/// Unique identifier for this download.
@property(nonatomic, copy, readonly) NSString* identifier;

/// Display name of the file being downloaded.
@property(nonatomic, copy, readonly) NSString* fileName;

/// Type of content being downloaded.
@property(nonatomic, assign, readonly) ActiveDownloadType downloadType;

/// Current state of the download.
@property(nonatomic, assign) ActiveDownloadState state;

/// Download progress from 0.0 to 1.0.
@property(nonatomic, assign) float progress;

/// Number of bytes received so far.
@property(nonatomic, assign) int64_t bytesReceived;

/// Total expected bytes (may be 0 if unknown).
@property(nonatomic, assign) int64_t totalBytes;

/// Source URL of the download.
@property(nonatomic, copy, readonly) NSURL* sourceURL;

/// Error if the download failed.
@property(nonatomic, strong) NSError* error;

/// Block to cancel this download. Set by the component that initiated the
/// download.
@property(nonatomic, copy) void (^cancelBlock)(void);

/// Initializes a new download item.
/// @param identifier Unique identifier for this download.
/// @param fileName Display name of the file.
/// @param downloadType Type of content being downloaded.
/// @param sourceURL Source URL of the download.
- (instancetype)initWithIdentifier:(NSString*)identifier
                          fileName:(NSString*)fileName
                      downloadType:(ActiveDownloadType)downloadType
                         sourceURL:(NSURL*)sourceURL NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Returns a human-readable progress string (e.g., "45 MB / 100 MB").
- (NSString*)progressString;

/// Returns YES if the download can be cancelled.
- (BOOL)isCancellable;

@end

#endif  // IOS_CHROME_BROWSER_DRIVE_BROWSER_MODEL_ACTIVE_DOWNLOAD_ITEM_H_
