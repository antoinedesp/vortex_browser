// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/web/model/adblocker/adblocker_filter_list_loader.h"

#include <fstream>

#include "base/apple/bundle_locations.h"
#include "base/apple/foundation_util.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/strings/string_split.h"
#include "base/strings/string_util.h"
#include "base/threading/scoped_blocking_call.h"
#include "base/threading/thread_restrictions.h"

namespace adblocker {

FilterList::FilterList() = default;
FilterList::~FilterList() = default;
FilterList::FilterList(const FilterList&) = default;
FilterList& FilterList::operator=(const FilterList&) = default;
FilterList::FilterList(FilterList&&) = default;
FilterList& FilterList::operator=(FilterList&&) = default;

namespace {

// Checks if a line is a cosmetic filter (element hiding rule)
bool IsCosmeticFilter(const std::string& line) {
  // Cosmetic filters use ## or #@# syntax
  return line.find("##") != std::string::npos ||
         line.find("#@#") != std::string::npos ||
         line.find("#?#") != std::string::npos;  // Extended CSS selectors
}

// Checks if a line is an exception rule
bool IsExceptionRule(const std::string& line) {
  return base::StartsWith(line, "@@");
}

}  // namespace

// static
std::string FilterListLoader::ReadBundledFilterFile(
    const std::string& filename) {
  // Allow blocking for file I/O from bundle resources
  // This is a bundled resource, so the read should be fast
  // TODO(adblocker): Load filter list asynchronously at startup and cache
  base::ScopedAllowBlockingForTesting allow_blocking;

  // Get the path to the bundled filter file
  NSString* filename_ns = @(filename.c_str());
  NSString* resource_path = [base::apple::FrameworkBundle()
      pathForResource:[filename_ns stringByDeletingPathExtension]
               ofType:[filename_ns pathExtension]];

  if (!resource_path) {
    LOG(ERROR) << "AdBlocker: Failed to find bundled filter file: " << filename;
    return "";
  }

  base::FilePath file_path =
      base::apple::NSStringToFilePath(resource_path);

  std::string content;
  if (!base::ReadFileToString(file_path, &content)) {
    LOG(ERROR) << "AdBlocker: Failed to read filter file: " << filename;
    return "";
  }

  return content;
}

// static
FilterList FilterListLoader::LoadEasyList() {
  LOG(INFO) << "AdBlocker: Loading EasyList filter";
  std::string content = ReadBundledFilterFile("easylist.txt");
  if (content.empty()) {
    LOG(WARNING) << "AdBlocker: EasyList not found, using empty filter list";
    return FilterList();
  }
  return ParseFilterList(content);
}

// static
FilterList FilterListLoader::ParseFilterList(
    const std::string& filter_content) {
  FilterList result;

  std::vector<std::string> lines = base::SplitString(
      filter_content, "\n", base::TRIM_WHITESPACE, base::SPLIT_WANT_NONEMPTY);

  int network_count = 0;
  int cosmetic_count = 0;
  int exception_count = 0;

  for (const auto& line : lines) {
    // Skip comments and metadata
    if (line.empty() || line[0] == '!' || line[0] == '[') {
      continue;
    }

    // Categorize the filter
    if (IsCosmeticFilter(line)) {
      result.cosmetic_filters.push_back(line);
      cosmetic_count++;
    } else if (IsExceptionRule(line)) {
      result.exception_filters.push_back(line);
      exception_count++;
    } else {
      result.network_filters.push_back(line);
      network_count++;
    }
  }

  LOG(INFO) << "AdBlocker: Parsed filter list - Network: " << network_count
            << ", Cosmetic: " << cosmetic_count
            << ", Exceptions: " << exception_count;

  return result;
}

}  // namespace adblocker