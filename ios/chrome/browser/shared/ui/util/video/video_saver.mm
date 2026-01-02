// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/shared/ui/util/video/video_saver.h"

#import <Photos/Photos.h>

#import "base/strings/sys_string_conversions.h"
#import "ios/chrome/browser/shared/model/browser/browser.h"
#import "ios/web/public/navigation/referrer.h"
#import "net/base/apple/url_conversions.h"

@interface VideoSaver ()
// Base view controller for the alerts.
@property(nonatomic, weak) UIViewController* baseViewController;
@property(nonatomic, readonly) Browser* browser;
@end

@implementation VideoSaver {
  // Alert to give feedback to the user.
  UIAlertController* _alertController;
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

  __weak VideoSaver* weakSelf = self;
  NSURLSessionDownloadTask* downloadTask =
      [[NSURLSession sharedSession]
          downloadTaskWithRequest:request
                completionHandler:^(NSURL* location, NSURLResponse* response,
                                    NSError* error) {
                  if (error || !location) {
                    [weakSelf displayPrivacyErrorAlertOnMainQueue:
                                  @"Unable to download video. Check your "
                                  @"internet connection."];
                    return;
                  }

                  // Check HTTP status code
                  if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSInteger statusCode =
                        [(NSHTTPURLResponse*)response statusCode];
                    if (statusCode < 200 || statusCode >= 300) {
                      [weakSelf displayPrivacyErrorAlertOnMainQueue:
                                    @"Unable to download video. Server error."];
                      return;
                    }
                  }

                  // Move file to a permanent temp location before processing
                  NSString* tempDir = NSTemporaryDirectory();
                  NSString* fileName = [NSString
                      stringWithFormat:@"video_%@.mp4",
                                       [[NSUUID UUID] UUIDString]];
                  NSString* destPath =
                      [tempDir stringByAppendingPathComponent:fileName];
                  NSURL* destURL = [NSURL fileURLWithPath:destPath];

                  NSError* moveError = nil;
                  [[NSFileManager defaultManager] moveItemAtURL:location
                                                          toURL:destURL
                                                          error:&moveError];
                  if (moveError) {
                    [weakSelf displayPrivacyErrorAlertOnMainQueue:
                                  @"Unable to save video. Please try again."];
                    return;
                  }

                  [weakSelf saveVideoFileToPhotos:destURL];
                }];
  [downloadTask resume];
}

#pragma mark - Private

// Save the video file to Photos library
- (void)saveVideoFileToPhotos:(NSURL*)fileURL {
  __weak VideoSaver* weakSelf = self;
  [[PHPhotoLibrary sharedPhotoLibrary]
      performChanges:^{
        PHAssetResourceCreationOptions* options =
            [[PHAssetResourceCreationOptions alloc] init];
        [[PHAssetCreationRequest creationRequestForAsset]
            addResourceWithType:PHAssetResourceTypeVideo
                        fileURL:fileURL
                        options:options];
      }
      completionHandler:^(BOOL success, NSError* error) {
        // Clean up temp file
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];

        [weakSelf videoDidFinishSavingWithError:error];
      }];
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
  NSString* message = @"The video has been saved to your Photos library.";
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
