// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_SHARED_UI_UTIL_VIDEO_VIDEO_SAVER_H_
#define IOS_CHROME_BROWSER_SHARED_UI_UTIL_VIDEO_VIDEO_SAVER_H_

#import <UIKit/UIKit.h>

class Browser;
class GURL;
namespace web {
class WebState;
struct Referrer;
}  // namespace web

// Object saving videos to the system's Photos library.
@interface VideoSaver : NSObject

// Init the VideoSaver.
- (instancetype)initWithBrowser:(Browser*)browser;

// Fetches and saves the video at `url` to the system's Photos library.
// `web_state` is used for fetching video data and must not be nullptr.
// `referrer` is used for download. `baseViewController` used to display alerts.
- (void)saveVideoAtURL:(const GURL&)URL
              referrer:(const web::Referrer&)referrer
              webState:(web::WebState*)webState
    baseViewController:(UIViewController*)baseViewController;

// Stops the video saver.
- (void)stop;

// Returns YES if the domain of `url` is blocked for video download.
+ (BOOL)isDomainBlockedForVideoDownload:(NSURL*)url;

@end

#endif  // IOS_CHROME_BROWSER_SHARED_UI_UTIL_VIDEO_VIDEO_SAVER_H_