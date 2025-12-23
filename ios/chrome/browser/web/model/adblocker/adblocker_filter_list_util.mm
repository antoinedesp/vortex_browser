// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/web/model/adblocker/adblocker_filter_list_util.h"

#include <vector>

#include "base/strings/string_split.h"
#include "base/strings/string_util.h"
#include "base/strings/sys_string_conversions.h"

namespace adblocker {

namespace {

// Represents a parsed Adblock Plus filter rule
struct FilterRule {
  std::string url_pattern;
  bool is_exception = false;  // @@-prefixed rules
  bool third_party_only = false;
  std::vector<std::string> domains;  // domain= option
  std::vector<std::string> resource_types;  // script, image, etc.
};

// Converts an Adblock Plus URL pattern to WebKit's url-filter regex
std::string ConvertAdblockPatternToRegex(const std::string& pattern) {
  std::string regex = pattern;

  // Remove leading || (domain anchor)
  bool is_domain_anchor = base::StartsWith(regex, "||");
  if (is_domain_anchor) {
    regex = regex.substr(2);
  }

  // Escape regex special characters except * and ^
  std::string escaped;
  for (char c : regex) {
    if (c == '.' || c == '+' || c == '?' || c == '[' || c == ']' ||
        c == '(' || c == ')' || c == '{' || c == '}' || c == '|' ||
        c == '\\' || c == '$') {
      escaped += '\\';
      escaped += c;
    } else if (c == '*') {
      // * matches any characters
      escaped += ".*";
    } else if (c == '^') {
      // ^ matches separator character (anything except letter, digit, -, ., %)
      escaped += "[^a-zA-Z0-9.%_-]";
    } else {
      escaped += c;
    }
  }

  // Add domain anchor if needed
  if (is_domain_anchor) {
    // Match https?://domain or https?://subdomain.domain
    return "https?://([^/]+\\.)?" + escaped;
  }

  return escaped;
}

// Parses a single Adblock Plus filter line
std::optional<FilterRule> ParseFilterLine(const std::string& line) {
  // Skip comments and empty lines
  if (line.empty() || line[0] == '!' || line[0] == '[') {
    return std::nullopt;
  }

  FilterRule rule;

  // Check for exception rule (@@)
  std::string filter = line;
  if (base::StartsWith(filter, "@@")) {
    rule.is_exception = true;
    filter = filter.substr(2);
  }

  // Check for element hiding rules (##) - not supported
  if (filter.find("##") != std::string::npos ||
      filter.find("#@#") != std::string::npos) {
    return std::nullopt;  // Skip cosmetic filters
  }

  // Split filter and options ($)
  size_t options_pos = filter.find('$');
  std::string pattern = filter;
  std::string options;

  if (options_pos != std::string::npos) {
    pattern = filter.substr(0, options_pos);
    options = filter.substr(options_pos + 1);

    // Parse options
    std::vector<std::string> option_list = base::SplitString(
        options, ",", base::TRIM_WHITESPACE, base::SPLIT_WANT_NONEMPTY);

    for (const auto& option : option_list) {
      if (option == "third-party") {
        rule.third_party_only = true;
      } else if (base::StartsWith(option, "domain=")) {
        std::string domain_list = option.substr(7);
        rule.domains = base::SplitString(
            domain_list, "|", base::TRIM_WHITESPACE, base::SPLIT_WANT_NONEMPTY);
      } else if (option == "script") {
        rule.resource_types.push_back("script");
      } else if (option == "image") {
        rule.resource_types.push_back("image");
      } else if (option == "stylesheet") {
        rule.resource_types.push_back("style-sheet");
      } else if (option == "xmlhttprequest") {
        rule.resource_types.push_back("raw");
      }
    }
  }

  rule.url_pattern = ConvertAdblockPatternToRegex(pattern);
  return rule;
}

}  // namespace

std::string ConvertAdblockFiltersToContentRuleListJSON(
    const std::string& filter_list_content) {
  std::vector<std::string> lines = base::SplitString(
      filter_list_content, "\n", base::TRIM_WHITESPACE,
      base::SPLIT_WANT_NONEMPTY);

  NSMutableArray* rules = [NSMutableArray array];

  for (const auto& line : lines) {
    std::optional<FilterRule> rule = ParseFilterLine(line);
    if (!rule.has_value()) {
      continue;
    }

    NSMutableDictionary* trigger = [NSMutableDictionary dictionary];
    trigger[@"url-filter"] = base::SysUTF8ToNSString(rule->url_pattern);

    // Add resource types if specified
    if (!rule->resource_types.empty()) {
      NSMutableArray* types = [NSMutableArray array];
      for (const auto& type : rule->resource_types) {
        [types addObject:base::SysUTF8ToNSString(type)];
      }
      trigger[@"resource-type"] = types;
    }

    // Add domain restrictions if specified
    if (!rule->domains.empty()) {
      NSMutableArray* if_domain = [NSMutableArray array];
      for (const auto& domain : rule->domains) {
        if (!base::StartsWith(domain, "~")) {  // Exclude negated domains
          // Convert domain to regex pattern
          [if_domain addObject:base::SysUTF8ToNSString("*" + domain + "*")];
        }
      }
      if ([if_domain count] > 0) {
        trigger[@"if-domain"] = if_domain;
      }
    }

    NSMutableDictionary* action = [NSMutableDictionary dictionary];
    if (rule->is_exception) {
      action[@"type"] = @"ignore-previous-rules";
    } else {
      action[@"type"] = @"block";
    }

    NSDictionary* content_rule = @{
      @"trigger" : trigger,
      @"action" : action,
    };

    [rules addObject:content_rule];

    // WKContentRuleList has a limit of 50,000 rules per list
    if ([rules count] >= 50000) {
      break;
    }
  }

  NSData* json_data =
      [NSJSONSerialization dataWithJSONObject:rules
                                      options:NSJSONWritingPrettyPrinted
                                        error:nil];
  NSString* json_string = [[NSString alloc] initWithData:json_data
                                                encoding:NSUTF8StringEncoding];
  return base::SysNSStringToUTF8(json_string);
}

NSString* CreateBasicAdBlockingJsonRuleList() {
  // Basic list of common ad/tracker domains
  NSArray* ad_domains = @[
    @"doubleclick.net",
    @"googleadservices.com",
    @"googlesyndication.com",
    @"google-analytics.com",
    @"googletagmanager.com",
    @"facebook.com/tr/",
    @"facebook.net/en_US/fbevents.js",
    @"connect.facebook.net",
    @"adservice.google.com",
    @"pagead2.googlesyndication.com",
  ];

  NSMutableArray* rules = [NSMutableArray array];

  // Create blocking rules for each domain
  for (NSString* domain in ad_domains) {
    NSDictionary* rule = @{
      @"trigger" : @{
        @"url-filter" : [NSString stringWithFormat:@".*%@.*", domain],
        @"resource-type" : @[ @"script", @"image", @"raw" ],
      },
      @"action" : @{
        @"type" : @"block",
      },
    };
    [rules addObject:rule];
  }

  NSData* json_data =
      [NSJSONSerialization dataWithJSONObject:rules
                                      options:NSJSONWritingPrettyPrinted
                                        error:nil];
  NSString* json_string = [[NSString alloc] initWithData:json_data
                                                encoding:NSUTF8StringEncoding];
  return json_string;
}

}  // namespace adblocker