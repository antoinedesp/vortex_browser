// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_JAVA_SCRIPT_FEATURE_H_
#define IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_JAVA_SCRIPT_FEATURE_H_

#include <optional>

#include "base/no_destructor.h"
#include "ios/web/public/js_messaging/java_script_feature.h"

class PrefService;

namespace web {
class BrowserState;
}

// A feature which injects ad-blocking JavaScript into web pages when the
// AdBlocker preference is enabled.
class AdBlockerJavaScriptFeature : public web::JavaScriptFeature {
 public:
  // Returns the singleton instance of this feature.
  static AdBlockerJavaScriptFeature* GetInstance();

  AdBlockerJavaScriptFeature(const AdBlockerJavaScriptFeature&) = delete;
  AdBlockerJavaScriptFeature& operator=(const AdBlockerJavaScriptFeature&) =
      delete;

 private:
  friend class base::NoDestructor<AdBlockerJavaScriptFeature>;

  AdBlockerJavaScriptFeature();
  ~AdBlockerJavaScriptFeature() override;

  // JavaScriptFeature:
  // Note: We override GetScripts() instead of providing scripts in constructor
  // to allow dynamic script injection based on preference state.
  std::vector<web::JavaScriptFeature::FeatureScript>
  GetScripts() const override;
};

#endif  // IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_JAVA_SCRIPT_FEATURE_H_
