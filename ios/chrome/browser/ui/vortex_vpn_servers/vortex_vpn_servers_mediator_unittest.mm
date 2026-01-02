// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_servers_mediator.h"

#import "base/test/task_environment.h"
#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_server.h"
#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_server_item.h"
#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_servers_consumer.h"
#import "testing/gtest/include/gtest/gtest.h"
#import "testing/platform_test.h"
#import "third_party/ocmock/OCMock/OCMock.h"

// Mock consumer for testing.
@interface MockVPNServersConsumer : NSObject <VortexVPNServersConsumer>
@property(nonatomic, assign) BOOL showLoadingCalled;
@property(nonatomic, copy) NSString* lastErrorMessage;
@property(nonatomic, copy) NSArray<VortexVPNServerItem*>* lastServers;
@property(nonatomic, strong) VortexVPNServer* lastSelectedServer;
@end

@implementation MockVPNServersConsumer

- (void)showLoading {
  self.showLoadingCalled = YES;
}

- (void)showError:(NSString*)message {
  self.lastErrorMessage = message;
}

- (void)showServers:(NSArray<VortexVPNServerItem*>*)servers {
  self.lastServers = servers;
}

- (void)updateSelectedServer:(VortexVPNServer*)server {
  self.lastSelectedServer = server;
}

@end

namespace {

// Test data for creating mock servers.
NSDictionary* CreateMockServerData(NSString* uuid,
                                    NSString* ip,
                                    NSString* country,
                                    BOOL isOnline,
                                    BOOL isPremium) {
  return @{
    @"id" : @1,
    @"uuid" : uuid,
    @"ip" : ip,
    @"port" : @0,
    @"username" : @"testuser",
    @"password" : @"testpass",
    @"is_online" : @(isOnline),
    @"is_premium" : @(isPremium),
    @"country" : country,
    @"psk" : @"testpsk123",
    @"flag" : @""
  };
}

class VortexVPNServersMediatorTest : public PlatformTest {
 protected:
  void SetUp() override {
    PlatformTest::SetUp();
    mediator_ = [[VortexVPNServersMediator alloc] init];
    consumer_ = [[MockVPNServersConsumer alloc] init];
    mediator_.consumer = consumer_;
  }

  void TearDown() override {
    [mediator_ disconnect];
    mediator_ = nil;
    consumer_ = nil;
    PlatformTest::TearDown();
  }

  VortexVPNServersMediator* mediator_;
  MockVPNServersConsumer* consumer_;
  base::test::TaskEnvironment task_environment_;
};

// Tests that VortexVPNServer can be created from a dictionary.
TEST_F(VortexVPNServersMediatorTest, TestServerFromDictionary) {
  NSDictionary* dict = CreateMockServerData(@"test-uuid-1234", @"192.168.1.1",
                                             @"us", YES, NO);

  VortexVPNServer* server = [VortexVPNServer serverFromDictionary:dict];

  ASSERT_TRUE(server != nil);
  EXPECT_TRUE([server.uuid isEqualToString:@"test-uuid-1234"]);
  EXPECT_TRUE([server.ip isEqualToString:@"192.168.1.1"]);
  EXPECT_TRUE([server.country isEqualToString:@"us"]);
  EXPECT_TRUE(server.isOnline);
  EXPECT_FALSE(server.isPremium);
}

// Tests that VortexVPNServer returns nil for invalid data.
TEST_F(VortexVPNServersMediatorTest, TestServerFromInvalidDictionary) {
  // Missing required IP field
  NSDictionary* dict = @{
    @"uuid" : @"test-uuid",
    @"psk" : @"testpsk"
  };

  VortexVPNServer* server = [VortexVPNServer serverFromDictionary:dict];

  EXPECT_TRUE(server == nil);
}

// Tests that VortexVPNServerItem can be created for auto option.
TEST_F(VortexVPNServersMediatorTest, TestAutoOptionItem) {
  VortexVPNServerItem* item = [VortexVPNServerItem autoOptionItemWithSelected:YES];

  EXPECT_TRUE(item.isAutoOption);
  EXPECT_TRUE(item.isSelected);
  EXPECT_TRUE(item.isEnabled);
  EXPECT_TRUE(item.server == nil);
}

// Tests that VortexVPNServerItem can be created from a server.
TEST_F(VortexVPNServersMediatorTest, TestServerItem) {
  NSDictionary* dict = CreateMockServerData(@"test-uuid", @"10.0.0.1",
                                             @"nl", YES, YES);
  VortexVPNServer* server = [VortexVPNServer serverFromDictionary:dict];

  VortexVPNServerItem* item = [VortexVPNServerItem itemWithServer:server
                                                         selected:NO
                                                          enabled:YES];

  EXPECT_FALSE(item.isAutoOption);
  EXPECT_FALSE(item.isSelected);
  EXPECT_TRUE(item.isEnabled);
  EXPECT_TRUE(item.isPremium);
  EXPECT_TRUE(item.isOnline);
  EXPECT_TRUE(item.server == server);
}

// Tests country display name mapping.
TEST_F(VortexVPNServersMediatorTest, TestCountryDisplayName) {
  NSDictionary* dict = CreateMockServerData(@"test-uuid", @"10.0.0.1",
                                             @"us", YES, NO);
  VortexVPNServer* server = [VortexVPNServer serverFromDictionary:dict];

  NSString* displayName = [server countryDisplayName];

  EXPECT_TRUE([displayName isEqualToString:@"United States"]);
}

// Tests unknown country code handling.
TEST_F(VortexVPNServersMediatorTest, TestUnknownCountryCode) {
  NSDictionary* dict = CreateMockServerData(@"test-uuid", @"10.0.0.1",
                                             @"xx", YES, NO);
  VortexVPNServer* server = [VortexVPNServer serverFromDictionary:dict];

  NSString* displayName = [server countryDisplayName];

  EXPECT_TRUE([displayName isEqualToString:@"XX"]);
}

}  // namespace
