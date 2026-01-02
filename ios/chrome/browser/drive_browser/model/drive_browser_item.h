// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_DRIVE_BROWSER_MODEL_DRIVE_BROWSER_ITEM_H_
#define IOS_CHROME_BROWSER_DRIVE_BROWSER_MODEL_DRIVE_BROWSER_ITEM_H_

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "base/files/file_path.h"
#import "base/time/time.h"

/// Represents the type of file in the drive browser.
typedef NS_ENUM(NSInteger, DriveBrowserFileType) {
  DriveBrowserFileTypeVideo,
  DriveBrowserFileTypeImage,
  DriveBrowserFileTypeDocument,
  DriveBrowserFileTypeArchive,
  DriveBrowserFileTypeOther,
};

/// Represents available actions for a drive browser item.
typedef NS_OPTIONS(NSUInteger, DriveBrowserItemAction) {
  DriveBrowserItemActionNone = 0,
  DriveBrowserItemActionPreview = 1 << 0,
  DriveBrowserItemActionShare = 1 << 1,
  DriveBrowserItemActionOpenInFiles = 1 << 2,
  DriveBrowserItemActionDelete = 1 << 3,
};

/// Represents a file item in the drive browser.
@interface DriveBrowserItem : NSObject

/// The display name of the file.
@property(nonatomic, copy, readonly) NSString* fileName;

/// The absolute file path.
@property(nonatomic, assign, readonly) base::FilePath filePath;

/// The type of file (video, image, document, etc.).
@property(nonatomic, assign, readonly) DriveBrowserFileType fileType;

/// The size of the file in bytes.
@property(nonatomic, assign, readonly) int64_t fileSize;

/// The MIME type of the file.
@property(nonatomic, copy, readonly) NSString* mimeType;

/// The creation/download date of the file.
@property(nonatomic, assign, readonly) base::Time createdTime;

/// The SF Symbol icon for the file type.
@property(nonatomic, strong, readonly) UIImage* fileTypeIcon;

/// The icon tint color for the file type.
@property(nonatomic, strong, readonly) UIColor* fileTypeIconColor;

/// The formatted file size string (e.g., "2.5 MB").
@property(nonatomic, copy, readonly) NSString* formattedFileSize;

/// The formatted date string.
@property(nonatomic, copy, readonly) NSString* formattedDate;

/// The detail text combining size and date.
@property(nonatomic, copy, readonly) NSString* detailText;

/// The available actions for this item.
@property(nonatomic, assign, readonly) DriveBrowserItemAction availableActions;

/// Initializes a drive browser item with file attributes.
- (instancetype)initWithFilePath:(const base::FilePath&)filePath
                        fileSize:(int64_t)fileSize
                        mimeType:(NSString*)mimeType
                     createdTime:(base::Time)createdTime
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Returns whether the current item is equal to another drive browser item.
- (BOOL)isEqualToItem:(DriveBrowserItem*)item;

@end

#endif  // IOS_CHROME_BROWSER_DRIVE_BROWSER_MODEL_DRIVE_BROWSER_ITEM_H_
