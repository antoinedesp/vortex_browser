// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_SERVICE_FACTORY_H_
#define IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_SERVICE_FACTORY_H_

#include <memory>

#include "base/no_destructor.h"
#include "ios/chrome/browser/shared/model/profile/profile_keyed_service_factory_ios.h"

class ProfileIOS;

namespace adblocker {
class AdBlockerContentRuleManager;
}

// Singleton that owns all AdBlockerContentRuleManagers and associates them
// with ProfileIOS.
class AdBlockerServiceFactory : public ProfileKeyedServiceFactoryIOS {
 public:
  static adblocker::AdBlockerContentRuleManager* GetForProfile(
      ProfileIOS* profile);
  static AdBlockerServiceFactory* GetInstance();

  AdBlockerServiceFactory(const AdBlockerServiceFactory&) = delete;
  AdBlockerServiceFactory& operator=(const AdBlockerServiceFactory&) = delete;

 private:
  friend class base::NoDestructor<AdBlockerServiceFactory>;

  AdBlockerServiceFactory();
  ~AdBlockerServiceFactory() override = default;

  // ProfileKeyedServiceFactoryIOS implementation.
  std::unique_ptr<KeyedService> BuildServiceInstanceFor(
      ProfileIOS* profile) const override;
};

#endif  // IOS_CHROME_BROWSER_WEB_MODEL_ADBLOCKER_ADBLOCKER_SERVICE_FACTORY_H_