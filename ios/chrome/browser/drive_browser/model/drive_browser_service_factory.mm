// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/drive_browser/model/drive_browser_service_factory.h"

#import <memory>

#import "ios/chrome/browser/drive_browser/model/drive_browser_service.h"
#import "ios/chrome/browser/shared/model/profile/profile_ios.h"

DriveBrowserServiceFactory* DriveBrowserServiceFactory::GetInstance() {
  static base::NoDestructor<DriveBrowserServiceFactory> instance;
  return instance.get();
}

DriveBrowserService* DriveBrowserServiceFactory::GetForProfile(
    ProfileIOS* profile) {
  CHECK(profile);
  return GetInstance()->GetServiceForProfileAs<DriveBrowserService>(
      profile, /*create=*/true);
}

DriveBrowserServiceFactory::DriveBrowserServiceFactory()
    : ProfileKeyedServiceFactoryIOS("DriveBrowserService",
                                    ProfileSelection::kRedirectedInIncognito) {}

DriveBrowserServiceFactory::~DriveBrowserServiceFactory() = default;

std::unique_ptr<KeyedService>
DriveBrowserServiceFactory::BuildServiceInstanceFor(ProfileIOS* profile) const {
  return std::make_unique<DriveBrowserService>();
}
