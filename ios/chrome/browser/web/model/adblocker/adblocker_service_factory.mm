// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/web/model/adblocker/adblocker_service_factory.h"

#include "base/no_destructor.h"
#include "ios/chrome/browser/content_settings/model/host_content_settings_map_factory.h"
#include "ios/chrome/browser/shared/model/profile/profile_ios.h"
#include "ios/chrome/browser/web/model/adblocker/adblocker_content_rule_manager.h"

// static
adblocker::AdBlockerContentRuleManager* AdBlockerServiceFactory::GetForProfile(
    ProfileIOS* profile) {
  return GetInstance()->GetServiceForProfileAs<adblocker::AdBlockerContentRuleManager>(
      profile, /*create=*/true);
}

// static
AdBlockerServiceFactory* AdBlockerServiceFactory::GetInstance() {
  static base::NoDestructor<AdBlockerServiceFactory> instance;
  return instance.get();
}

AdBlockerServiceFactory::AdBlockerServiceFactory()
    : ProfileKeyedServiceFactoryIOS("AdBlockerService",
                                    ProfileSelection::kOwnInstanceInIncognito,
                                    ServiceCreation::kCreateWithProfile,
                                    TestingCreation::kNoServiceForTests) {
  DependsOn(ios::HostContentSettingsMapFactory::GetInstance());
}

std::unique_ptr<KeyedService> AdBlockerServiceFactory::BuildServiceInstanceFor(
    ProfileIOS* profile) const {
  LOG(INFO) << "AdBlocker: BuildServiceInstanceFor called for profile";
  return std::make_unique<adblocker::AdBlockerContentRuleManager>(profile);
}
