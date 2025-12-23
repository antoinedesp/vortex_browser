// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_CONTENT_RULE_MANAGER_H_
#define IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_CONTENT_RULE_MANAGER_H_

#include "base/memory/raw_ptr.h"
#include "base/memory/weak_ptr.h"
#include "components/keyed_service/core/keyed_service.h"
#include "components/prefs/pref_change_registrar.h"

@class NSError;

class PrefService;

namespace web {
class BrowserState;
class WKContentRuleListProvider;
}  // namespace web

namespace adblocker {

// Manages ad-blocking content rules for a BrowserState.
// This class:
// - Monitors the AdBlocker preference
// - Installs/removes WKContentRuleList based on preference state
// - Handles filter list updates
//
// The rules are applied at the WebKit level, blocking network requests
// before they are made.
class AdBlockerContentRuleManager : public KeyedService {
 public:
  // The identifier for the ad-blocking content rule list
  static constexpr char kAdBlockerRuleListKey[] = "AdBlocker";

  explicit AdBlockerContentRuleManager(web::BrowserState* browser_state);
  ~AdBlockerContentRuleManager() override;

  AdBlockerContentRuleManager(const AdBlockerContentRuleManager&) = delete;
  AdBlockerContentRuleManager& operator=(const AdBlockerContentRuleManager&) =
      delete;

  // Enables ad-blocking by installing content rules
  void Enable();

  // Disables ad-blocking by removing content rules
  void Disable();

  // Returns whether ad-blocking is currently enabled
  bool IsEnabled() const;

 private:
  // Called when the AdBlocker preference changes
  void OnPrefChanged();

  // Callback invoked after content rules are installed or removed
  void OnRuleListUpdated(NSError* error);

  raw_ptr<web::BrowserState> browser_state_ = nullptr;
  raw_ptr<PrefService> pref_service_ = nullptr;
  raw_ptr<web::WKContentRuleListProvider> rule_list_provider_ = nullptr;

  // Observes changes to the AdBlocker preference
  PrefChangeRegistrar pref_change_registrar_;

  // Whether content rules are currently installed
  bool rules_installed_ = false;

  base::WeakPtrFactory<AdBlockerContentRuleManager> weak_ptr_factory_{this};
};

}  // namespace adblocker

#endif  // IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_CONTENT_RULE_MANAGER_H_
