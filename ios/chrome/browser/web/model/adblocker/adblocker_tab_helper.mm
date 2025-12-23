// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/web/model/adblocker/adblocker_tab_helper.h"

#include "base/task/sequenced_task_runner.h"
#include "base/values.h"
#include "components/prefs/pref_service.h"
#include "ios/chrome/browser/shared/model/prefs/pref_names.h"
#include "ios/chrome/browser/shared/model/profile/profile_ios.h"
#include "ios/chrome/browser/web/model/adblocker/adblocker_filter_list_loader.h"
#include "ios/chrome/browser/web/model/adblocker/adblocker_java_script_feature.h"
#include "ios/chrome/browser/web/model/adblocker/adblocker_service_factory.h"
#include "ios/web/public/browser_state.h"
#include "ios/web/public/js_messaging/web_frames_manager.h"
#include "ios/web/public/navigation/navigation_context.h"
#include "ios/web/public/web_state.h"
#include "ios/web/public/web_state_observer.h"

AdBlockerTabHelper::AdBlockerTabHelper(web::WebState* web_state)
    : web_state_(web_state) {
  DCHECK(web_state_);

  web_state_observation_.Observe(web_state);

  // Get the PrefService from the BrowserState
  web::BrowserState* browser_state = web_state->GetBrowserState();
  ProfileIOS* profile = ProfileIOS::FromBrowserState(browser_state);
  if (profile) {
    pref_service_ = profile->GetPrefs();

    // Observe changes to the AdBlocker preference for cosmetic filtering
    if (pref_service_) {
      pref_change_registrar_.Init(pref_service_);
      pref_change_registrar_.Add(
          prefs::kAdBlockerEnabled,
          base::BindRepeating(&AdBlockerTabHelper::OnAdBlockerPrefChanged,
                              base::Unretained(this)));
    }
  }
}

AdBlockerTabHelper::~AdBlockerTabHelper() = default;

bool AdBlockerTabHelper::IsAdBlockerEnabled() const {
  if (!pref_service_) {
    return false;
  }
  return pref_service_->GetBoolean(prefs::kAdBlockerEnabled);
}

void AdBlockerTabHelper::WebStateDestroyed(web::WebState* web_state) {
  DCHECK_EQ(web_state_, web_state);
  web_state_observation_.Reset();
  web_state_ = nullptr;
}

void AdBlockerTabHelper::DidFinishNavigation(
    web::WebState* web_state,
    web::NavigationContext* navigation_context) {
  DCHECK_EQ(web_state_, web_state);
  // Don't update here - wait for PageLoaded when main frame is available
}

void AdBlockerTabHelper::PageLoaded(
    web::WebState* web_state,
    web::PageLoadCompletionStatus load_completion_status) {
  DCHECK_EQ(web_state_, web_state);

  // Update ad-blocking state when page is fully loaded and frame is available
  if (load_completion_status == web::PageLoadCompletionStatus::SUCCESS) {
    LOG(INFO) << "AdBlocker: Page loaded successfully, updating state";
    UpdateAdBlockingState();
  }
}

void AdBlockerTabHelper::OnAdBlockerPrefChanged() {
  // Preference changed, update the current page
  UpdateAdBlockingState();
}

void AdBlockerTabHelper::UpdateAdBlockingState() {
  if (!web_state_) {
    LOG(WARNING) << "AdBlocker: No web_state available";
    return;
  }

  // Get the main web frame
  web::WebFrame* main_frame =
      web_state_->GetPageWorldWebFramesManager()->GetMainWebFrame();
  if (!main_frame) {
    LOG(WARNING) << "AdBlocker: No main frame available yet";
    return;
  }

  LOG(INFO) << "AdBlocker: Updating blocking state, enabled="
            << IsAdBlockerEnabled();

  if (IsAdBlockerEnabled()) {
    // Load cosmetic filters and pass to JavaScript
    adblocker::FilterList filter_list = adblocker::FilterListLoader::LoadEasyList();

    // Limit cosmetic filters to avoid overwhelming the page
    // Take first 1000 most common filters
    std::vector<std::string> limited_filters;
    size_t limit = std::min(filter_list.cosmetic_filters.size(), size_t(1000));
    for (size_t i = 0; i < limit; i++) {
      limited_filters.push_back(filter_list.cosmetic_filters[i]);
    }

    // Set cosmetic filters in JavaScript
    LOG(INFO) << "AdBlocker: Setting " << limited_filters.size()
              << " cosmetic filters";
    SetCosmeticFilters(limited_filters);

    // Enable logging (can be configured via preference)
    LOG(INFO) << "AdBlocker: Enabling JavaScript logging";
    SetLogging(true);

    // Enable the adblocker
    LOG(INFO) << "AdBlocker: Calling JavaScript adBlocker.enable()";
    main_frame->CallJavaScriptFunction("adBlocker.enable",
                                       base::Value::List());
    LOG(INFO) << "AdBlocker: JavaScript enable() call completed";
  } else {
    // Disable the adblocker
    LOG(INFO) << "AdBlocker: Calling JavaScript adBlocker.disable()";
    main_frame->CallJavaScriptFunction("adBlocker.disable",
                                       base::Value::List());
  }
}

void AdBlockerTabHelper::SetCosmeticFilters(
    const std::vector<std::string>& filters) {
  if (!web_state_) {
    return;
  }

  web::WebFrame* main_frame =
      web_state_->GetPageWorldWebFramesManager()->GetMainWebFrame();
  if (!main_frame) {
    return;
  }

  // Convert filters to base::Value::List
  base::Value::List filters_list;
  for (const auto& filter : filters) {
    filters_list.Append(filter);
  }

  main_frame->CallJavaScriptFunction("adBlocker.setCosmeticFilters",
                                     std::move(filters_list));
}

void AdBlockerTabHelper::SetLogging(bool enabled) {
  if (!web_state_) {
    return;
  }

  web::WebFrame* main_frame =
      web_state_->GetPageWorldWebFramesManager()->GetMainWebFrame();
  if (!main_frame) {
    return;
  }

  base::Value::List params;
  params.Append(enabled);
  main_frame->CallJavaScriptFunction("adBlocker.setLogging",
                                     std::move(params));
}
