// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_DRIVE_BROWSER_COORDINATOR_DRIVE_BROWSER_MEDIATOR_DELEGATE_H_
#define IOS_CHROME_BROWSER_DRIVE_BROWSER_COORDINATOR_DRIVE_BROWSER_MEDIATOR_DELEGATE_H_

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "base/files/file_path.h"

@class DriveBrowserItem;

/// Delegate protocol for the drive browser mediator.
/// Used to communicate actions to the coordinator.
@protocol DriveBrowserMediatorDelegate <NSObject>

/// Called when the mediator wants to preview a file.
/// @param filePath The path of the file to preview.
/// @param mimeType The MIME type of the file.
- (void)presentFilePreviewWithPath:(const base::FilePath&)filePath
                          mimeType:(NSString*)mimeType;

/// Called when the mediator wants to share a file.
/// @param filePath The path of the file to share.
/// @param sourceView The view to anchor the share sheet to.
- (void)presentShareSheetWithPath:(const base::FilePath&)filePath
                       sourceView:(UIView*)sourceView;

/// Called when the mediator wants to open a file in the Files app.
/// @param filePath The path of the file to open.
- (void)openInFilesApp:(const base::FilePath&)filePath;

/// Called when a file was successfully deleted.
/// @param index The index of the deleted item.
- (void)didDeleteItemAtIndex:(NSUInteger)index;

/// Called when a delete operation failed.
/// @param item The item that failed to delete.
- (void)didFailToDeleteItem:(DriveBrowserItem*)item;

@end

#endif  // IOS_CHROME_BROWSER_DRIVE_BROWSER_COORDINATOR_DRIVE_BROWSER_MEDIATOR_DELEGATE_H_
