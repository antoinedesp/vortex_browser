// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_FILTER_LIST_UTIL_H_
#define IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_FILTER_LIST_UTIL_H_

#import <Foundation/Foundation.h>

#include <string>

namespace adblocker {

// Parses Adblock Plus filter list format and converts to WKContentRuleList
// JSON format for blocking ads and trackers.
//
// Supports a subset of Adblock Plus filter syntax:
// - URL blocking rules (e.g., ||ads.example.com^)
// - Domain-specific rules (e.g., ||ads.com^$domain=example.com)
// - Exception rules (e.g., @@||ads.com^)
// - Basic element hiding rules are NOT supported (requires different approach)
//
// Returns a JSON string that can be compiled by WKContentRuleListStore.
std::string ConvertAdblockFiltersToContentRuleListJSON(
    const std::string& filter_list_content);

// Creates a basic ad-blocking rule list JSON for common ad domains.
// This is a fallback/minimal filter list for testing or when the full
// EasyList cannot be loaded.
NSString* CreateBasicAdBlockingJsonRuleList();

}  // namespace adblocker

#endif  // IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_FILTER_LIST_UTIL_H_