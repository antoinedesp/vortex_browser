// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_DRIVE_BROWSER_TABLE_VIEW_CONTROLLER_H_
#define IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_DRIVE_BROWSER_TABLE_VIEW_CONTROLLER_H_

#import <UIKit/UIKit.h>

#import "ios/chrome/browser/drive_browser/ui/drive_browser_consumer.h"

@protocol DriveBrowserMutator;

/// Delegate protocol for drive browser table view controller actions.
@protocol DriveBrowserTableViewControllerDelegate <NSObject>

/// Called when the user dismisses the drive browser.
- (void)driveBrowserTableViewControllerDidDismiss;

@end

/// Table view controller for displaying files in the drive browser.
/// Presents a unified list of files sorted by date with swipe actions
/// for share, delete, and open in Files.
@interface DriveBrowserTableViewController
    : UITableViewController <DriveBrowserConsumer,
                             UIAdaptivePresentationControllerDelegate>

/// The mutator for handling user interactions.
@property(nonatomic, weak) id<DriveBrowserMutator> mutator;

/// The delegate for handling dismissal.
@property(nonatomic, weak) id<DriveBrowserTableViewControllerDelegate> delegate;

/// Initializes the table view controller with the given style.
- (instancetype)initWithStyle:(UITableViewStyle)style
    NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCoder:(NSCoder*)coder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(NSString*)nibNameOrNil
                         bundle:(NSBundle*)nibBundleOrNil NS_UNAVAILABLE;

@end

#endif  // IOS_CHROME_BROWSER_DRIVE_BROWSER_UI_DRIVE_BROWSER_TABLE_VIEW_CONTROLLER_H_
