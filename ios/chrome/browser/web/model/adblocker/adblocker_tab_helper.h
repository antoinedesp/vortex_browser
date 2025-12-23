// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_TAB_HELPER_H_
#define IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_TAB_HELPER_H_

#include "base/memory/raw_ptr.h"
#include "base/scoped_observation.h"
#include "components/prefs/pref_change_registrar.h"
#include "ios/web/public/web_state_observer.h"
#import "ios/web/public/web_state_user_data.h"

class PrefService;

// TabHelper that manages ad-blocking functionality for a WebState.
// This helper:
// - Monitors the AdBlocker preference
// - Manages script injection based on pref state
// - Coordinates with AdBlockerJavaScriptFeature for actual blocking
class AdBlockerTabHelper : public web::WebStateObserver,
                           public web::WebStateUserData<AdBlockerTabHelper> {
 public:
  ~AdBlockerTabHelper() override;

  AdBlockerTabHelper(const AdBlockerTabHelper&) = delete;
  AdBlockerTabHelper& operator=(const AdBlockerTabHelper&) = delete;

  // Returns whether ad-blocking is currently enabled for this WebState.
  bool IsAdBlockerEnabled() const;

  // Sets cosmetic filters in JavaScript for element hiding
  void SetCosmeticFilters(const std::vector<std::string>& filters);

  // Sets logging enabled/disabled in JavaScript
  void SetLogging(bool enabled);

 private:
  friend class web::WebStateUserData<AdBlockerTabHelper>;

  explicit AdBlockerTabHelper(web::WebState* web_state);

  // web::WebStateObserver:
  void WebStateDestroyed(web::WebState* web_state) override;
  void DidFinishNavigation(web::WebState* web_state,
                           web::NavigationContext* navigation_context) override;
  void PageLoaded(web::WebState* web_state,
                  web::PageLoadCompletionStatus load_completion_status) override;

  // Called when the AdBlocker preference changes.
  void OnAdBlockerPrefChanged();

  // Updates the ad-blocking state for the current page.
  void UpdateAdBlockingState();

  // The WebState this helper is attached to.
  raw_ptr<web::WebState> web_state_ = nullptr;

  // The preference service for checking AdBlocker state.
  raw_ptr<PrefService> pref_service_ = nullptr;

  // Observes changes to the AdBlocker preference.
  PrefChangeRegistrar pref_change_registrar_;

  // Observes the WebState.
  base::ScopedObservation<web::WebState, web::WebStateObserver>
      web_state_observation_{this};
};

#endif  // IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_TAB_HELPER_H_
