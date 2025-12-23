// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/web/model/adblocker/adblocker_content_rule_manager.h"

#include "base/functional/bind.h"
#include "base/logging.h"
#include "base/strings/sys_string_conversions.h"
#include "components/prefs/pref_service.h"
#include "ios/chrome/browser/shared/model/prefs/pref_names.h"
#include "ios/chrome/browser/shared/model/profile/profile_ios.h"
#include "ios/chrome/browser/web/model/adblocker/adblocker_filter_list_loader.h"
#include "ios/chrome/browser/web/model/adblocker/adblocker_filter_list_util.h"
#include "ios/web/public/browser_state.h"
#include "ios/web/web_state/ui/wk_content_rule_list_provider.h"
#include "ios/web/web_state/ui/wk_web_view_configuration_provider.h"

namespace adblocker {

constexpr char AdBlockerContentRuleManager::kAdBlockerRuleListKey[];

AdBlockerContentRuleManager::AdBlockerContentRuleManager(
    web::BrowserState* browser_state)
    : browser_state_(browser_state) {
  DCHECK(browser_state_);

  LOG(INFO) << "AdBlocker: ContentRuleManager constructor called";

  // Get the PrefService
  ProfileIOS* profile = ProfileIOS::FromBrowserState(browser_state_);
  if (profile) {
    pref_service_ = profile->GetPrefs();
  }

  // Get the WKContentRuleListProvider from the configuration provider
  web::WKWebViewConfigurationProvider& config_provider =
      web::WKWebViewConfigurationProvider::FromBrowserState(browser_state_);
  rule_list_provider_ = &config_provider.GetContentRuleListProvider();

  // Observe preference changes
  if (pref_service_) {
    bool initial_state = IsEnabled();
    LOG(INFO) << "AdBlocker: Initial preference state: "
              << (initial_state ? "enabled" : "disabled");

    pref_change_registrar_.Init(pref_service_);
    pref_change_registrar_.Add(
        prefs::kAdBlockerEnabled,
        base::BindRepeating(&AdBlockerContentRuleManager::OnPrefChanged,
                            base::Unretained(this)));

    // Apply initial state based on current preference
    if (initial_state) {
      Enable();
    }
  } else {
    LOG(WARNING) << "AdBlocker: No PrefService available!";
  }
}

AdBlockerContentRuleManager::~AdBlockerContentRuleManager() {
  // Clean up: remove rules if they're installed
  if (rules_installed_ && rule_list_provider_) {
    Disable();
  }
}

void AdBlockerContentRuleManager::Enable() {
  if (rules_installed_ || !rule_list_provider_) {
    return;
  }

  LOG(INFO) << "AdBlocker: Installing content blocking rules";

  // Load and parse EasyList
  FilterList filter_list = FilterListLoader::LoadEasyList();

  // Convert network filters to WKContentRuleList JSON
  std::string combined_filters;
  for (const auto& filter : filter_list.network_filters) {
    combined_filters += filter + "\n";
  }
  for (const auto& filter : filter_list.exception_filters) {
    combined_filters += filter + "\n";
  }

  std::string rules_json_str;
  if (!combined_filters.empty()) {
    rules_json_str =
        ConvertAdblockFiltersToContentRuleListJSON(combined_filters);
  } else {
    LOG(WARNING)
        << "AdBlocker: No network filters found, using basic filter list";
    NSString* rules_json = CreateBasicAdBlockingJsonRuleList();
    rules_json_str = base::SysNSStringToUTF8(rules_json);
  }

  // Install the rules via WKContentRuleListProvider
  rule_list_provider_->UpdateRuleList(
      kAdBlockerRuleListKey, rules_json_str,
      base::BindOnce(&AdBlockerContentRuleManager::OnRuleListUpdated,
                     weak_ptr_factory_.GetWeakPtr()));

  rules_installed_ = true;

  LOG(INFO) << "AdBlocker: Installed " << filter_list.network_filters.size()
            << " network filters, " << filter_list.cosmetic_filters.size()
            << " cosmetic filters";

  // TODO: Pass cosmetic filters to JavaScript for element hiding
}

void AdBlockerContentRuleManager::Disable() {
  if (!rules_installed_ || !rule_list_provider_) {
    return;
  }

  LOG(INFO) << "AdBlocker: Removing content blocking rules";

  // Remove the rules via WKContentRuleListProvider
  rule_list_provider_->RemoveRuleList(
      kAdBlockerRuleListKey,
      base::BindOnce(&AdBlockerContentRuleManager::OnRuleListUpdated,
                     weak_ptr_factory_.GetWeakPtr()));

  rules_installed_ = false;
}

bool AdBlockerContentRuleManager::IsEnabled() const {
  if (!pref_service_) {
    return false;
  }
  return pref_service_->GetBoolean(prefs::kAdBlockerEnabled);
}

void AdBlockerContentRuleManager::OnPrefChanged() {
  LOG(INFO) << "AdBlocker: Preference changed to "
            << (IsEnabled() ? "enabled" : "disabled");

  if (IsEnabled()) {
    Enable();
  } else {
    Disable();
  }
}

void AdBlockerContentRuleManager::OnRuleListUpdated(NSError* error) {
  if (error) {
    LOG(ERROR) << "AdBlocker: Failed to update content rules: "
               << base::SysNSStringToUTF8([error localizedDescription]);
  } else {
    LOG(INFO) << "AdBlocker: Content rules updated successfully";
  }
}

}  // namespace adblocker
