// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_FILTER_LIST_LOADER_H_
#define IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_FILTER_LIST_LOADER_H_

#include <string>
#include <vector>

namespace adblocker {

// Represents a parsed filter list with separated network and cosmetic rules
struct FilterList {
  FilterList();
  ~FilterList();
  FilterList(const FilterList&);
  FilterList& operator=(const FilterList&);
  FilterList(FilterList&&);
  FilterList& operator=(FilterList&&);

  // Network blocking rules (URL patterns) - for WKContentRuleList
  std::vector<std::string> network_filters;

  // Cosmetic filtering rules (element hiding) - for JavaScript
  std::vector<std::string> cosmetic_filters;

  // Exception rules (whitelist)
  std::vector<std::string> exception_filters;
};

// Loads and parses the bundled EasyList filter file
class FilterListLoader {
 public:
  // Loads the bundled EasyList filter
  static FilterList LoadEasyList();

  // Loads a custom filter list from a string
  static FilterList ParseFilterList(const std::string& filter_content);

 private:
  // Reads the bundled filter file from resources
  static std::string ReadBundledFilterFile(const std::string& filename);
};

}  // namespace adblocker

#endif  // IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_FILTER_LIST_LOADER_H_