// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_servers_view_controller.h"

#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_server.h"
#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_server_item.h"
#import "ios/chrome/browser/ui/vortex_vpn_servers/vortex_vpn_servers_mutator.h"
#import "ios/chrome/grit/ios_strings.h"
#import "ui/base/l10n/l10n_util.h"

namespace {
NSString* const kServerCellReuseIdentifier = @"VPNServerCell";
}  // namespace

typedef NS_ENUM(NSInteger, VPNServersState) {
  VPNServersStateLoading,
  VPNServersStateError,
  VPNServersStateLoaded,
};

@interface VortexVPNServersViewController ()
@property(nonatomic, assign) VPNServersState state;
@property(nonatomic, copy) NSString* errorMessage;
@property(nonatomic, copy) NSArray<VortexVPNServerItem*>* serverItems;
@end

@implementation VortexVPNServersViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = l10n_util::GetNSString(IDS_IOS_VPN_SERVERS_TITLE);

  // Configure Done button
  UIBarButtonItem* doneButton = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                           target:self
                           action:@selector(doneButtonTapped)];
  self.navigationItem.rightBarButtonItem = doneButton;

  // Configure table view
  self.tableView.rowHeight = UITableViewAutomaticDimension;
  self.tableView.estimatedRowHeight = 60;
  [self.tableView registerClass:[UITableViewCell class]
         forCellReuseIdentifier:kServerCellReuseIdentifier];
}

#pragma mark - Actions

- (void)doneButtonTapped {
  [self.delegate viewControllerDidRequestDismissal:self];
}

- (void)retryButtonTapped {
  [self.mutator didRequestRetry];
}

#pragma mark - VortexVPNServersConsumer

- (void)showLoading {
  self.state = VPNServersStateLoading;
  self.serverItems = nil;
  self.errorMessage = nil;
  [self.tableView reloadData];
}

- (void)showError:(NSString*)message {
  self.state = VPNServersStateError;
  self.errorMessage = message;
  self.serverItems = nil;
  [self.tableView reloadData];
}

- (void)showServers:(NSArray<VortexVPNServerItem*>*)servers {
  self.state = VPNServersStateLoaded;
  self.serverItems = servers;
  self.errorMessage = nil;
  [self.tableView reloadData];
}

- (void)updateSelectedServer:(VortexVPNServer*)server {
  // Refresh the table to show new selection
  [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView
    numberOfRowsInSection:(NSInteger)section {
  switch (self.state) {
    case VPNServersStateLoading:
      return 1;  // Loading cell
    case VPNServersStateError:
      return 1;  // Error cell
    case VPNServersStateLoaded:
      return self.serverItems.count;
  }
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  UITableViewCell* cell =
      [tableView dequeueReusableCellWithIdentifier:kServerCellReuseIdentifier
                                      forIndexPath:indexPath];

  switch (self.state) {
    case VPNServersStateLoading:
      [self configureLoadingCell:cell];
      break;
    case VPNServersStateError:
      [self configureErrorCell:cell];
      break;
    case VPNServersStateLoaded:
      [self configureServerCell:cell atIndexPath:indexPath];
      break;
  }

  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView
    didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  if (self.state == VPNServersStateLoaded && (NSUInteger)indexPath.row < self.serverItems.count) {
    VortexVPNServerItem* item = self.serverItems[indexPath.row];
    if (item.isEnabled) {
      [self.mutator didSelectServerItem:item];
    }
  } else if (self.state == VPNServersStateError) {
    [self retryButtonTapped];
  }
}

#pragma mark - Cell Configuration

- (void)configureLoadingCell:(UITableViewCell*)cell {
  cell.textLabel.text = l10n_util::GetNSString(IDS_IOS_VPN_SERVERS_CONNECTING);
  cell.textLabel.textAlignment = NSTextAlignmentCenter;
  cell.textLabel.textColor = [UIColor secondaryLabelColor];
  cell.detailTextLabel.text = nil;
  cell.accessoryType = UITableViewCellAccessoryNone;
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.imageView.image = nil;

  UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc]
      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
  [spinner startAnimating];
  cell.accessoryView = spinner;
}

- (void)configureErrorCell:(UITableViewCell*)cell {
  cell.textLabel.text = self.errorMessage;
  cell.textLabel.textAlignment = NSTextAlignmentCenter;
  cell.textLabel.textColor = [UIColor systemRedColor];
  cell.textLabel.numberOfLines = 0;
  cell.detailTextLabel.text = nil;
  cell.accessoryType = UITableViewCellAccessoryNone;
  cell.selectionStyle = UITableViewCellSelectionStyleDefault;
  cell.accessoryView = nil;
  cell.imageView.image = nil;
}

- (void)configureServerCell:(UITableViewCell*)cell
                atIndexPath:(NSIndexPath*)indexPath {
  VortexVPNServerItem* item = self.serverItems[indexPath.row];

  // Reset cell
  cell.accessoryView = nil;
  cell.textLabel.textAlignment = NSTextAlignmentNatural;

  // Configure content
  if (item.isAutoOption) {
    cell.textLabel.text = item.title;
    cell.detailTextLabel.text = item.subtitle;
    cell.imageView.image = [UIImage systemImageNamed:@"wand.and.stars"];
    cell.imageView.tintColor = [UIColor systemBlueColor];
  } else {
    cell.textLabel.text = item.title;
    cell.detailTextLabel.text = item.subtitle;

    // Country flag emoji
    NSString* flagEmoji = [self flagEmojiForCountryCode:item.countryCode];
    if (flagEmoji) {
      UILabel* flagLabel = [[UILabel alloc] init];
      flagLabel.text = flagEmoji;
      flagLabel.font = [UIFont systemFontOfSize:24];
      [flagLabel sizeToFit];
      cell.imageView.image = nil;
      // We can't easily add a custom view to imageView, so use text instead
    }
    cell.imageView.image = [UIImage systemImageNamed:@"server.rack"];
    cell.imageView.tintColor = item.isOnline ? [UIColor systemGreenColor]
                                              : [UIColor systemGrayColor];
  }

  // Premium badge
  if (item.isPremium && !item.isAutoOption) {
    UILabel* premiumLabel = [[UILabel alloc] init];
    premiumLabel.text = l10n_util::GetNSString(IDS_IOS_VPN_SERVERS_PREMIUM);
    premiumLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    premiumLabel.textColor = [UIColor whiteColor];
    premiumLabel.backgroundColor = [UIColor systemOrangeColor];
    premiumLabel.layer.cornerRadius = 4;
    premiumLabel.layer.masksToBounds = YES;
    premiumLabel.textAlignment = NSTextAlignmentCenter;
    [premiumLabel sizeToFit];
    premiumLabel.frame = CGRectInset(premiumLabel.frame, -6, -2);

    if (!item.isEnabled) {
      // Show premium required message
      cell.detailTextLabel.text =
          l10n_util::GetNSString(IDS_IOS_VPN_SERVERS_PREMIUM_REQUIRED);
    }
  }

  // Selection state
  cell.accessoryType =
      item.isSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

  // Enabled state
  if (item.isEnabled) {
    cell.textLabel.textColor = [UIColor labelColor];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.contentView.alpha = 1.0;
  } else {
    cell.textLabel.textColor = [UIColor tertiaryLabelColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.contentView.alpha = 0.6;
  }

  // Offline indicator
  if (!item.isOnline && !item.isAutoOption) {
    cell.detailTextLabel.text =
        l10n_util::GetNSString(IDS_IOS_VPN_SERVERS_OFFLINE);
    cell.detailTextLabel.textColor = [UIColor systemRedColor];
  }
}

#pragma mark - Helpers

- (NSString*)flagEmojiForCountryCode:(NSString*)countryCode {
  if (!countryCode || countryCode.length != 2) {
    return nil;
  }

  NSString* code = countryCode.uppercaseString;
  unichar firstChar = [code characterAtIndex:0] - 'A' + 0x1F1E6;
  unichar secondChar = [code characterAtIndex:1] - 'A' + 0x1F1E6;

  return [NSString stringWithFormat:@"%C%C", firstChar, secondChar];
}

@end
