// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_DRIVE_BROWSER_COORDINATOR_DRIVE_BROWSER_MEDIATOR_H_
#define IOS_CHROME_BROWSER_DRIVE_BROWSER_COORDINATOR_DRIVE_BROWSER_MEDIATOR_H_

#import <Foundation/Foundation.h>

#import "ios/chrome/browser/drive_browser/ui/drive_browser_mutator.h"

@protocol DriveBrowserConsumer;
@protocol DriveBrowserMediatorDelegate;
class DriveBrowserService;

/// Mediator for the drive browser feature.
/// Handles business logic and connects the service to the UI.
@interface DriveBrowserMediator : NSObject <DriveBrowserMutator>

/// The consumer for UI updates.
@property(nonatomic, weak) id<DriveBrowserConsumer> consumer;

/// The delegate for coordinator actions.
@property(nonatomic, weak) id<DriveBrowserMediatorDelegate> delegate;

/// Initializes the mediator with the drive browser service.
/// @param service The service for file operations.
- (instancetype)initWithService:(DriveBrowserService*)service
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Connects the mediator and starts fetching files.
- (void)connect;

/// Disconnects the mediator and cleans up resources.
- (void)disconnect;

@end

#endif  // IOS_CHROME_BROWSER_DRIVE_BROWSER_COORDINATOR_DRIVE_BROWSER_MEDIATOR_H_
