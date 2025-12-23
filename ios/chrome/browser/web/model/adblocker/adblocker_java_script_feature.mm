// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/web/model/adblocker/adblocker_java_script_feature.h"

#include "base/no_destructor.h"
#include "components/prefs/pref_service.h"
#include "ios/chrome/browser/shared/model/prefs/pref_names.h"
#include "ios/chrome/browser/shared/model/profile/profile_ios.h"
#include "ios/web/public/browser_state.h"
#include "ios/web/public/js_messaging/java_script_feature_util.h"
#include "ios/web/public/js_messaging/web_frame.h"
#include "ios/web/public/web_state.h"

namespace {
const char kScriptName[] = "adblocker";
}  // namespace

// static
AdBlockerJavaScriptFeature* AdBlockerJavaScriptFeature::GetInstance() {
  static base::NoDestructor<AdBlockerJavaScriptFeature> instance;
  return instance.get();
}

AdBlockerJavaScriptFeature::AdBlockerJavaScriptFeature()
    : JavaScriptFeature(
          web::ContentWorld::kPageContentWorld,
          // Scripts are dynamically provided via GetScripts()
          {},
          {web::java_script_features::GetCommonJavaScriptFeature()}) {}

AdBlockerJavaScriptFeature::~AdBlockerJavaScriptFeature() = default;

std::vector<web::JavaScriptFeature::FeatureScript>
AdBlockerJavaScriptFeature::GetScripts() const {
  // Check if AdBlocker is enabled via WebState if available
  // Note: This is called during injection, so we need to get the current state

  // For now, we'll inject the script and let it check the preference
  // A more sophisticated approach would pass the WebState/BrowserState here
  // and check the pref before deciding to inject.

  // TODO(adblocker): Implement pref checking here once we have access to
  // the current WebState/BrowserState context during GetScripts() call.
  // For now, the script itself will check the preference state.

  std::vector<web::JavaScriptFeature::FeatureScript> scripts;
  scripts.push_back(FeatureScript::CreateWithFilename(
      kScriptName,
      FeatureScript::InjectionTime::kDocumentStart,
      FeatureScript::TargetFrames::kMainFrame,
      FeatureScript::ReinjectionBehavior::kInjectOncePerWindow));

  return scripts;
}
