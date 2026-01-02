// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_DRIVE_BROWSER_MODEL_DRIVE_BROWSER_SERVICE_FACTORY_H_
#define IOS_CHROME_BROWSER_DRIVE_BROWSER_MODEL_DRIVE_BROWSER_SERVICE_FACTORY_H_

#import "base/no_destructor.h"
#import "ios/chrome/browser/shared/model/profile/profile_keyed_service_factory_ios.h"

class DriveBrowserService;

/// A factory to create a unique `DriveBrowserService` per profile.
class DriveBrowserServiceFactory : public ProfileKeyedServiceFactoryIOS {
 public:
  static DriveBrowserServiceFactory* GetInstance();
  static DriveBrowserService* GetForProfile(ProfileIOS* profile);

 private:
  friend class base::NoDestructor<DriveBrowserServiceFactory>;

  DriveBrowserServiceFactory();
  ~DriveBrowserServiceFactory() override;

  std::unique_ptr<KeyedService> BuildServiceInstanceFor(
      ProfileIOS* profile) const override;
};

#endif  // IOS_CHROME_BROWSER_DRIVE_BROWSER_MODEL_DRIVE_BROWSER_SERVICE_FACTORY_H_
