// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/drive_browser/ui/drive_browser_empty_view.h"

#import "ios/chrome/browser/drive_browser/ui/drive_browser_constants.h"
#import "ios/chrome/common/ui/colors/semantic_color_names.h"
#import "ios/chrome/grit/ios_strings.h"
#import "ui/base/l10n/l10n_util_mac.h"

namespace {

// Layout constants for the empty view.
const CGFloat kIconSize = 80.0;
const CGFloat kSpacing = 16.0;
const CGFloat kMaxWidth = 280.0;

}  // namespace

@implementation DriveBrowserEmptyView {
  UIImageView* _iconView;
  UILabel* _titleLabel;
  UILabel* _subtitleLabel;
  UIStackView* _stackView;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupViews];
    [self setupConstraints];
  }
  return self;
}

#pragma mark - Private Methods

- (void)setupViews {
  self.accessibilityIdentifier = kDriveBrowserEmptyViewAccessibilityId;

  // Icon view.
  UIImageConfiguration* config = [UIImageSymbolConfiguration
      configurationWithPointSize:kIconSize
                          weight:UIImageSymbolWeightLight];
  UIImage* icon = [UIImage systemImageNamed:@"folder" withConfiguration:config];
  _iconView = [[UIImageView alloc] initWithImage:icon];
  _iconView.tintColor = [UIColor colorNamed:kTextSecondaryColor];
  _iconView.contentMode = UIViewContentModeCenter;
  _iconView.translatesAutoresizingMaskIntoConstraints = NO;

  // Title label.
  _titleLabel = [[UILabel alloc] init];
  _titleLabel.text =
      l10n_util::GetNSString(IDS_IOS_DOWNLOAD_LIST_NO_ENTRIES_TITLE);
  _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
  _titleLabel.textColor = [UIColor colorNamed:kTextPrimaryColor];
  _titleLabel.textAlignment = NSTextAlignmentCenter;
  _titleLabel.numberOfLines = 0;
  _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

  // Subtitle label.
  _subtitleLabel = [[UILabel alloc] init];
  _subtitleLabel.text =
      l10n_util::GetNSString(IDS_IOS_DOWNLOAD_LIST_NO_ENTRIES_MESSAGE);
  _subtitleLabel.font =
      [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
  _subtitleLabel.textColor = [UIColor colorNamed:kTextSecondaryColor];
  _subtitleLabel.textAlignment = NSTextAlignmentCenter;
  _subtitleLabel.numberOfLines = 0;
  _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;

  // Stack view.
  _stackView = [[UIStackView alloc]
      initWithArrangedSubviews:@[ _iconView, _titleLabel, _subtitleLabel ]];
  _stackView.axis = UILayoutConstraintAxisVertical;
  _stackView.alignment = UIStackViewAlignmentCenter;
  _stackView.spacing = kSpacing;
  _stackView.translatesAutoresizingMaskIntoConstraints = NO;

  [self addSubview:_stackView];
}

- (void)setupConstraints {
  [NSLayoutConstraint activateConstraints:@[
    [_stackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
    [_stackView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [_stackView.widthAnchor constraintLessThanOrEqualToConstant:kMaxWidth],
    [_stackView.leadingAnchor
        constraintGreaterThanOrEqualToAnchor:self.leadingAnchor
                                    constant:kSpacing],
    [_stackView.trailingAnchor
        constraintLessThanOrEqualToAnchor:self.trailingAnchor
                                 constant:-kSpacing],
  ]];
}

@end
