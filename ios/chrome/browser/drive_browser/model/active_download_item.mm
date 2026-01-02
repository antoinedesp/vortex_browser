// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/drive_browser/model/active_download_item.h"

NSString* const kActiveDownloadAddedNotification =
    @"ActiveDownloadAddedNotification";
NSString* const kActiveDownloadUpdatedNotification =
    @"ActiveDownloadUpdatedNotification";

@implementation ActiveDownloadItem

- (instancetype)initWithIdentifier:(NSString*)identifier
                          fileName:(NSString*)fileName
                      downloadType:(ActiveDownloadType)downloadType
                         sourceURL:(NSURL*)sourceURL {
  self = [super init];
  if (self) {
    _identifier = [identifier copy];
    _fileName = [fileName copy];
    _downloadType = downloadType;
    _sourceURL = [sourceURL copy];
    _state = ActiveDownloadStateInProgress;
    _progress = 0.0f;
    _bytesReceived = 0;
    _totalBytes = 0;
  }
  return self;
}

- (NSString*)progressString {
  if (self.totalBytes <= 0) {
    // Unknown total size - just show received bytes.
    return [self formattedBytes:self.bytesReceived];
  }

  NSString* received = [self formattedBytes:self.bytesReceived];
  NSString* total = [self formattedBytes:self.totalBytes];
  return [NSString stringWithFormat:@"%@ / %@", received, total];
}

- (BOOL)isCancellable {
  return self.state == ActiveDownloadStateInProgress && self.cancelBlock != nil;
}

#pragma mark - Private

- (NSString*)formattedBytes:(int64_t)bytes {
  static NSByteCountFormatter* formatter = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    formatter = [[NSByteCountFormatter alloc] init];
    formatter.countStyle = NSByteCountFormatterCountStyleFile;
  });
  return [formatter stringFromByteCount:bytes];
}

@end
