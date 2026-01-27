// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/first_run/ui_bundled/att_prompt/att_prompt_view_controller.h"

#import "ios/chrome/browser/first_run/ui_bundled/first_run_constants.h"
#import "ios/chrome/browser/shared/ui/symbols/symbols.h"
#import "ios/chrome/common/ui/button_stack/button_stack_configuration.h"
#import "ios/chrome/common/ui/colors/semantic_color_names.h"
#import "ios/chrome/grit/ios_strings.h"
#import "ui/base/l10n/l10n_util.h"

namespace {
// Layout constants.
const CGFloat kTitleTopMargin = 60.0;
const CGFloat kSubtitleBottomMargin = 40.0;
const CGFloat kTitleHorizontalMargin = 24.0;
const CGFloat kIconSize = 80.0;
}  // namespace

@implementation ATTPromptViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
  self.view.accessibilityIdentifier =
      first_run::kATTPromptScreenAccessibilityIdentifier;

  // Hide banner and use promo style background for cleaner look.
  self.shouldHideBanner = YES;
  self.usePromoStyleBackground = YES;

  // Set generous margins for better visual appearance.
  self.titleTopMarginWhenNoHeaderImage = kTitleTopMargin;
  self.subtitleBottomMargin = kSubtitleBottomMargin;
  self.titleHorizontalMargin = kTitleHorizontalMargin;

  // Set title and subtitle text.
  self.titleText =
      l10n_util::GetNSString(IDS_IOS_FIRST_RUN_ATT_PROMPT_TITLE);
  self.subtitleText =
      l10n_util::GetNSString(IDS_IOS_FIRST_RUN_ATT_PROMPT_SUBTITLE);

  // Configure action buttons.
  self.configuration.primaryActionString =
      l10n_util::GetNSString(IDS_IOS_FIRST_RUN_ATT_PROMPT_PRIMARY_ACTION);
  self.configuration.secondaryActionString =
      l10n_util::GetNSString(IDS_IOS_FIRST_RUN_ATT_PROMPT_SECONDARY_ACTION);

  // Add an icon to the specific content view.
  [self setupIconView];

  [super viewDidLoad];
}

#pragma mark - Private

// Sets up the icon view displayed above the title.
- (void)setupIconView {
  UIImageSymbolConfiguration* config = [UIImageSymbolConfiguration
      configurationWithPointSize:kIconSize
                          weight:UIImageSymbolWeightLight];
  UIImage* icon = [UIImage systemImageNamed:@"hand.raised.circle.fill"
                          withConfiguration:config];

  UIImageView* iconView = [[UIImageView alloc] initWithImage:icon];
  iconView.tintColor = [UIColor colorNamed:kBlueColor];
  iconView.contentMode = UIViewContentModeScaleAspectFit;
  iconView.translatesAutoresizingMaskIntoConstraints = NO;

  [self.specificContentView addSubview:iconView];

  [NSLayoutConstraint activateConstraints:@[
    [iconView.centerXAnchor
        constraintEqualToAnchor:self.specificContentView.centerXAnchor],
    [iconView.topAnchor
        constraintEqualToAnchor:self.specificContentView.topAnchor
                       constant:20],
    [iconView.bottomAnchor
        constraintLessThanOrEqualToAnchor:self.specificContentView.bottomAnchor],
    [iconView.widthAnchor constraintEqualToConstant:kIconSize],
    [iconView.heightAnchor constraintEqualToConstant:kIconSize],
  ]];
}

@end
