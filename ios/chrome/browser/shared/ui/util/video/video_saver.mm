// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/shared/ui/util/video/video_saver.h"

#import <Photos/Photos.h>

#import "base/files/file_path.h"
#import "base/strings/sys_string_conversions.h"
#import "ios/chrome/browser/download/model/download_directory_util.h"
#import "ios/chrome/browser/drive_browser/model/active_download_item.h"
#import "ios/chrome/browser/shared/model/browser/browser.h"
#import "ios/web/public/navigation/referrer.h"
#import "net/base/apple/url_conversions.h"

namespace {

// Generates a unique filename for saved videos.
NSString* GenerateVideoFileName() {
  NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"yyyyMMdd_HHmmss";
  NSString* timestamp = [formatter stringFromDate:[NSDate date]];
  return [NSString stringWithFormat:@"VID_%@.mp4", timestamp];
}

}  // namespace

@interface VideoSaver () <NSURLSessionDownloadDelegate>
// Base view controller for the alerts.
@property(nonatomic, weak) UIViewController* baseViewController;
@property(nonatomic, readonly) Browser* browser;
@end

@implementation VideoSaver {
  // Alert to give feedback to the user.
  UIAlertController* _alertController;
  // Active download item for progress tracking.
  ActiveDownloadItem* _activeDownloadItem;
  // URL session for download with progress tracking.
  NSURLSession* _urlSession;
  // Current download task.
  NSURLSessionDownloadTask* _downloadTask;
}

- (instancetype)initWithBrowser:(Browser*)browser {
  self = [super init];
  if (self) {
    _browser = browser;
  }
  return self;
}

- (void)stop {
  [self dismissAlert];
  self.baseViewController = nil;
  _browser = nullptr;
}

- (void)saveVideoAtURL:(const GURL&)URL
              referrer:(const web::Referrer&)referrer
              webState:(web::WebState*)webState
    baseViewController:(UIViewController*)baseViewController {
  self.baseViewController = baseViewController;

  // Use NSURLSession for video downloads - better for large files than
  // ImageFetchTabHelper which loads everything into memory.
  NSURL* videoURL = net::NSURLWithGURL(URL);
  if (!videoURL) {
    [self displayPrivacyErrorAlertOnMainQueue:
              @"Unable to download video. Invalid URL."];
    return;
  }

  NSMutableURLRequest* request =
      [NSMutableURLRequest requestWithURL:videoURL];
  [request setHTTPMethod:@"GET"];
  [request setTimeoutInterval:60.0];

  // Set referrer if available
  if (referrer.url.is_valid()) {
    NSString* referrerString =
        base::SysUTF8ToNSString(referrer.url.spec());
    [request setValue:referrerString forHTTPHeaderField:@"Referer"];
  }

  // Create active download item for progress tracking.
  NSString* fileName = GenerateVideoFileName();
  _activeDownloadItem = [[ActiveDownloadItem alloc]
      initWithIdentifier:[[NSUUID UUID] UUIDString]
                fileName:fileName
            downloadType:ActiveDownloadTypeVideo
               sourceURL:videoURL];

  // Set cancel block.
  __weak VideoSaver* weakSelf = self;
  _activeDownloadItem.cancelBlock = ^{
    [weakSelf cancelDownload];
  };

  // Notify that download has started.
  [[NSNotificationCenter defaultCenter]
      postNotificationName:kActiveDownloadAddedNotification
                    object:_activeDownloadItem];

  // Create URL session with delegate for progress tracking.
  NSURLSessionConfiguration* config =
      [NSURLSessionConfiguration defaultSessionConfiguration];
  _urlSession = [NSURLSession sessionWithConfiguration:config
                                              delegate:self
                                         delegateQueue:[NSOperationQueue mainQueue]];

  _downloadTask = [_urlSession downloadTaskWithRequest:request];
  [_downloadTask resume];
}

- (void)cancelDownload {
  if (_downloadTask) {
    [_downloadTask cancel];
    _downloadTask = nil;
  }
  if (_activeDownloadItem) {
    _activeDownloadItem.state = ActiveDownloadStateCancelled;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kActiveDownloadUpdatedNotification
                      object:_activeDownloadItem];
    _activeDownloadItem = nil;
  }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession*)session
                 downloadTask:(NSURLSessionDownloadTask*)downloadTask
                 didWriteData:(int64_t)bytesWritten
            totalBytesWritten:(int64_t)totalBytesWritten
    totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
  if (_activeDownloadItem) {
    _activeDownloadItem.bytesReceived = totalBytesWritten;
    _activeDownloadItem.totalBytes = totalBytesExpectedToWrite;
    if (totalBytesExpectedToWrite > 0) {
      _activeDownloadItem.progress =
          (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
    }

    [[NSNotificationCenter defaultCenter]
        postNotificationName:kActiveDownloadUpdatedNotification
                      object:_activeDownloadItem];
  }
}

- (void)URLSession:(NSURLSession*)session
                 downloadTask:(NSURLSessionDownloadTask*)downloadTask
    didFinishDownloadingToURL:(NSURL*)location {
  // Check HTTP status code.
  NSHTTPURLResponse* httpResponse =
      (NSHTTPURLResponse*)downloadTask.response;
  if (httpResponse && (httpResponse.statusCode < 200 ||
                       httpResponse.statusCode >= 300)) {
    _activeDownloadItem.state = ActiveDownloadStateFailed;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kActiveDownloadUpdatedNotification
                      object:_activeDownloadItem];
    [self displayPrivacyErrorAlertOnMainQueue:
              @"Unable to download video. Server error."];
    return;
  }

  [self saveVideoFileToDrive:location];
}

- (void)URLSession:(NSURLSession*)session
                    task:(NSURLSessionTask*)task
    didCompleteWithError:(NSError*)error {
  if (error) {
    if (error.code == NSURLErrorCancelled) {
      // Download was cancelled by user.
      return;
    }
    _activeDownloadItem.state = ActiveDownloadStateFailed;
    _activeDownloadItem.error = error;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kActiveDownloadUpdatedNotification
                      object:_activeDownloadItem];
    [self displayPrivacyErrorAlertOnMainQueue:
              @"Unable to download video. Check your internet connection."];
  }
}

#pragma mark - Private

// Save the video file to internal drive directory.
- (void)saveVideoFileToDrive:(NSURL*)tempFileURL {
  // Get the downloads directory.
  base::FilePath downloadsDir;
  GetDownloadsDirectory(&downloadsDir);

  NSString* fileName = _activeDownloadItem.fileName;
  base::FilePath destPath =
      downloadsDir.Append(base::SysNSStringToUTF8(fileName));
  NSString* destPathString = base::SysUTF8ToNSString(destPath.value());
  NSURL* destURL = [NSURL fileURLWithPath:destPathString];

  NSError* moveError = nil;
  [[NSFileManager defaultManager] moveItemAtURL:tempFileURL
                                          toURL:destURL
                                          error:&moveError];

  if (moveError) {
    _activeDownloadItem.state = ActiveDownloadStateFailed;
    _activeDownloadItem.error = moveError;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kActiveDownloadUpdatedNotification
                      object:_activeDownloadItem];
    [self videoDidFinishSavingWithError:moveError];
    return;
  }

  // Mark download as complete.
  _activeDownloadItem.progress = 1.0f;
  _activeDownloadItem.state = ActiveDownloadStateComplete;
  [[NSNotificationCenter defaultCenter]
      postNotificationName:kActiveDownloadUpdatedNotification
                    object:_activeDownloadItem];

  [self videoDidFinishSavingWithError:nil];
}

// Called after attempting to save the video
- (void)videoDidFinishSavingWithError:(NSError*)error {
  if (error) {
    [self handleVideoSaveError:error];
    return;
  }

  // Video saved successfully
  dispatch_async(dispatch_get_main_queue(), ^{
    [self showSuccessAlert];
  });
}

// Handle errors when saving video
- (void)handleVideoSaveError:(NSError*)error {
  PHAuthorizationStatus status =
      [PHPhotoLibrary authorizationStatusForAccessLevel:
                          PHAccessLevelAddOnly];

  if (status == PHAuthorizationStatusDenied) {
    [self displayVideoErrorAlertWithSettingsOnMainQueue];
  } else {
    [self displayPrivacyErrorAlertOnMainQueue:
              @"Unable to save video. Please try again."];
  }
}

// Show success alert
- (void)showSuccessAlert {
  [self dismissAlert];

  NSString* title = @"Video Saved";
  NSString* message = @"The video has been saved to Downloads.";
  _alertController =
      [UIAlertController alertControllerWithTitle:title
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction* okAction =
      [UIAlertAction actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                             handler:nil];
  [_alertController addAction:okAction];

  [self.baseViewController presentViewController:_alertController
                                        animated:YES
                                      completion:nil];
}

// Called when Vortex has been denied access to add photos or videos
- (void)displayVideoErrorAlertWithSettingsOnMainQueue {
  __weak VideoSaver* weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    NSURL* settingURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    BOOL canGoToSetting =
        [[UIApplication sharedApplication] canOpenURL:settingURL];
    if (canGoToSetting) {
      [weakSelf displayVideoErrorAlertWithSettings:settingURL];
    } else {
      [weakSelf displayPrivacyErrorAlertOnMainQueue:
                    @"Vortex does not have permission to access Photos."];
    }
  });
}

// Shows a privacy alert allowing the user to go to Vortex settings
- (void)displayVideoErrorAlertWithSettings:(NSURL*)settingURL {
  [self dismissAlert];

  NSString* title = @"Unable to Save Video";
  NSString* message = @"To save videos, allow Vortex to access Photos in Settings.";
  _alertController =
      [UIAlertController alertControllerWithTitle:title
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];

  [_alertController
      addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                         style:UIAlertActionStyleCancel
                                       handler:nil]];

  UIAlertAction* openSettings = [UIAlertAction
      actionWithTitle:@"Settings"
                style:UIAlertActionStyleDefault
              handler:^(UIAlertAction*) {
                [[UIApplication sharedApplication] openURL:settingURL
                                                   options:@{}
                                         completionHandler:nil];
              }];
  [_alertController addAction:openSettings];

  [self.baseViewController presentViewController:_alertController
                                        animated:YES
                                      completion:nil];
}

// Shows a privacy alert on the main queue, with a given `message`. Dismisses
// previous alert if it has not been dismissed yet.
- (void)displayPrivacyErrorAlertOnMainQueue:(NSString*)message {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self dismissAlert];
    NSString* title = @"Unable to Save Video";
    self->_alertController =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];

    [self->_alertController
        addAction:[UIAlertAction actionWithTitle:@"OK"
                                           style:UIAlertActionStyleDefault
                                         handler:nil]];

    [self.baseViewController presentViewController:self->_alertController
                                          animated:YES
                                        completion:nil];
  });
}

// Dismisses the alert if it exists.
- (void)dismissAlert {
  [_alertController.presentingViewController dismissViewControllerAnimated:YES
                                                                completion:nil];
  _alertController = nil;
}

+ (BOOL)isDomainBlockedForVideoDownload:(NSURL*)url {
  static NSSet* blockedDomains;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    blockedDomains = [NSSet setWithArray:@[
      @"youtube.com",
      @"m.youtube.com",
      @"youtu.be",
      @"youtube-nocookie.com",
      @"netflix.com",
      @"www.netflix.com",
      @"primevideo.com",
      @"www.primevideo.com",
      @"tiktok.com",
      @"m.tiktok.com",
      @"instagram.com",
      @"www.instagram.com",
      @"facebook.com",
      @"m.facebook.com",
      @"disneyplus.com",
      @"www.disneyplus.com",
      @"hulu.com",
      @"www.hulu.com",
      @"hbomax.com",
      @"hbo.com"
    ]];
  });

  NSString* host = url.host.lowercaseString;
  return [blockedDomains containsObject:host];
}

@end
