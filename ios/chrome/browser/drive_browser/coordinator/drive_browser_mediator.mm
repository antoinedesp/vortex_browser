// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/drive_browser/coordinator/drive_browser_mediator.h"

#import "base/functional/bind.h"
#import "base/strings/sys_string_conversions.h"
#import "ios/chrome/browser/drive_browser/coordinator/drive_browser_mediator_delegate.h"
#import "ios/chrome/browser/drive_browser/model/active_download_item.h"
#import "ios/chrome/browser/drive_browser/model/drive_browser_item.h"
#import "ios/chrome/browser/drive_browser/model/drive_browser_service.h"
#import "ios/chrome/browser/drive_browser/ui/drive_browser_consumer.h"

@implementation DriveBrowserMediator {
  /// The service for file operations.
  raw_ptr<DriveBrowserService> _service;

  /// The current list of completed file items.
  NSArray<DriveBrowserItem*>* _items;

  /// The current list of active downloads.
  NSMutableArray<ActiveDownloadItem*>* _activeDownloads;

  /// Whether the mediator is connected.
  BOOL _connected;
}

- (instancetype)initWithService:(DriveBrowserService*)service {
  self = [super init];
  if (self) {
    _service = service;
    _items = @[];
    _activeDownloads = [[NSMutableArray alloc] init];
  }
  return self;
}

#pragma mark - Public Methods

- (void)connect {
  if (_connected) {
    return;
  }
  _connected = YES;

  // Register for download notifications.
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(handleDownloadAdded:)
             name:kActiveDownloadAddedNotification
           object:nil];
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(handleDownloadUpdated:)
             name:kActiveDownloadUpdatedNotification
           object:nil];

  [self fetchFiles];
}

- (void)disconnect {
  if (!_connected) {
    return;
  }
  _connected = NO;

  // Unregister from download notifications.
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  _service = nullptr;
}

#pragma mark - DriveBrowserMutator

- (void)userDidSelectItem:(DriveBrowserItem*)item {
  if (!item) {
    return;
  }
  [self.delegate presentFilePreviewWithPath:item.filePath
                                   mimeType:item.mimeType];
}

- (void)userDidDeleteItem:(DriveBrowserItem*)item {
  if (!item || !_service) {
    return;
  }

  // Find the index of the item.
  NSUInteger index = [_items indexOfObject:item];
  if (index == NSNotFound) {
    return;
  }

  __weak __typeof(self) weakSelf = self;
  base::FilePath filePath = item.filePath;

  _service->DeleteFile(
      filePath, base::BindOnce(^(bool success) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }
        if (success) {
          // Update the items array.
          NSMutableArray* mutableItems = [strongSelf->_items mutableCopy];
          if (index < mutableItems.count) {
            [mutableItems removeObjectAtIndex:index];
            strongSelf->_items = mutableItems;
          }
          [strongSelf.delegate didDeleteItemAtIndex:index];
        } else {
          [strongSelf.delegate didFailToDeleteItem:item];
        }
      }));
}

- (void)userDidShareItem:(DriveBrowserItem*)item sourceView:(UIView*)sourceView {
  if (!item) {
    return;
  }
  [self.delegate presentShareSheetWithPath:item.filePath sourceView:sourceView];
}

- (void)userDidOpenInFilesApp:(DriveBrowserItem*)item {
  if (!item) {
    return;
  }
  [self.delegate openInFilesApp:item.filePath];
}

- (void)userDidRefresh {
  [self fetchFiles];
}

- (void)userDidCancelDownload:(ActiveDownloadItem*)item {
  if (!item) {
    return;
  }

  // Call the cancel block if available.
  if (item.cancelBlock) {
    item.cancelBlock();
  }

  // Remove from active downloads.
  [_activeDownloads removeObject:item];
  if ([self.consumer respondsToSelector:@selector(setActiveDownloads:)]) {
    [self.consumer setActiveDownloads:[_activeDownloads copy]];
  }
}

- (void)userDidRetryDownload:(ActiveDownloadItem*)item {
  // Retry is not implemented in MVP - would need to store original URL
  // and re-initiate the download.
}

#pragma mark - Notification Handlers

- (void)handleDownloadAdded:(NSNotification*)notification {
  ActiveDownloadItem* item = notification.object;
  if (!item) {
    return;
  }

  // Add to active downloads at the beginning.
  [_activeDownloads insertObject:item atIndex:0];

  // Notify consumer.
  if ([self.consumer respondsToSelector:@selector(setActiveDownloads:)]) {
    [self.consumer setActiveDownloads:[_activeDownloads copy]];
  }
}

- (void)handleDownloadUpdated:(NSNotification*)notification {
  ActiveDownloadItem* item = notification.object;
  if (!item) {
    return;
  }

  // Update the consumer with progress.
  if ([self.consumer
          respondsToSelector:@selector(updateDownloadProgress:progress:bytesReceived:totalBytes:)]) {
    [self.consumer updateDownloadProgress:item.identifier
                                 progress:item.progress
                            bytesReceived:item.bytesReceived
                               totalBytes:item.totalBytes];
  }

  // If download is complete, remove from active and refresh files.
  if (item.state == ActiveDownloadStateComplete) {
    [_activeDownloads removeObject:item];
    if ([self.consumer respondsToSelector:@selector(removeActiveDownload:)]) {
      [self.consumer removeActiveDownload:item.identifier];
    }
    // Refresh the file list to show the new file.
    [self fetchFiles];
  } else if (item.state == ActiveDownloadStateFailed ||
             item.state == ActiveDownloadStateCancelled) {
    // Remove failed/cancelled downloads after a short delay.
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          [self->_activeDownloads removeObject:item];
          if ([self.consumer respondsToSelector:@selector(setActiveDownloads:)]) {
            [self.consumer setActiveDownloads:[self->_activeDownloads copy]];
          }
        });
  }
}

#pragma mark - Private Methods

- (void)fetchFiles {
  if (!_service) {
    return;
  }

  [self.consumer setLoadingState:YES];

  __weak __typeof(self) weakSelf = self;
  _service->GetAllFiles(base::BindOnce(^(NSArray<DriveBrowserItem*>* items) {
    __strong __typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    strongSelf->_items = items;
    [strongSelf.consumer setLoadingState:NO];
    [strongSelf.consumer setItems:items];
  }));
}

@end
