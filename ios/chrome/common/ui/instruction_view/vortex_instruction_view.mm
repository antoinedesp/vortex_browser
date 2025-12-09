// Copyright 2024 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/common/ui/instruction_view/vortex_instruction_view.h"

#import "base/check.h"
#import "ios/chrome/common/string_util.h"
#import "ios/chrome/common/ui/colors/semantic_color_names.h"
#import "ios/chrome/common/ui/util/constraints_ui_util.h"
#import "ios/chrome/common/ui/util/dynamic_type_util.h"
#import "ios/chrome/common/ui/util/ui_util.h"

namespace {

constexpr CGFloat kCheckmarkSize = 24;
constexpr CGFloat kLeadingMargin = 15;
constexpr CGFloat kSpacing = 14;
constexpr CGFloat kVerticalMargin = 12;
constexpr CGFloat kTrailingMargin = 16;
constexpr CGFloat kCornerRadius = 12;
constexpr CGFloat kSeparatorLeadingMargin = 60;
constexpr CGFloat kSeparatorHeight = 0.5;
constexpr CGFloat kCheckmarkContainerWidth = 30;
// Height minimum for a line.
constexpr CGFloat kMinimumLineHeight = 44;

}  // namespace

@implementation VortexInstructionView

#pragma mark - Public

- (instancetype)initWithList:(NSArray<NSString*>*)instructionList {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    UIStackView* stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;

    // Add first instruction without separator
    UIView* firstCheckmark = [self createCheckmarkView];
    firstCheckmark.translatesAutoresizingMaskIntoConstraints = NO;
    [stackView addArrangedSubview:[self createLineInstruction:instructionList[0]
                                              checkmarkView:firstCheckmark
                                                      index:0]];

    // Add remaining instructions with separators
    for (NSUInteger i = 1; i < [instructionList count]; i++) {
      UIView* checkmark = [self createCheckmarkView];
      checkmark.translatesAutoresizingMaskIntoConstraints = NO;
      [stackView addArrangedSubview:[self createLineSeparator]];
      [stackView addArrangedSubview:[self createLineInstruction:instructionList[i]
                                                  checkmarkView:checkmark
                                                          index:i]];
    }

    [self addSubview:stackView];
    AddSameConstraints(self, stackView);

    // Background styling
    self.backgroundColor = [UIColor colorNamed:kSecondaryBackgroundColor];
    self.layer.cornerRadius = kCornerRadius;
  }
  return self;
}

#pragma mark - Private

// Creates a separator line between instructions.
- (UIView*)createLineSeparator {
  UIView* liner = [[UIView alloc] init];
  UIView* separator = [[UIView alloc] init];
  separator.backgroundColor = [UIColor colorNamed:kGrey300Color];
  separator.translatesAutoresizingMaskIntoConstraints = NO;

  [liner addSubview:separator];

  [NSLayoutConstraint activateConstraints:@[
    [separator.leadingAnchor constraintEqualToAnchor:liner.leadingAnchor
                                            constant:kSeparatorLeadingMargin],
    [separator.trailingAnchor constraintEqualToAnchor:liner.trailingAnchor],
    [separator.topAnchor constraintEqualToAnchor:liner.topAnchor],
    [separator.bottomAnchor constraintEqualToAnchor:liner.bottomAnchor],
    [liner.heightAnchor
        constraintEqualToConstant:AlignValueToPixel(kSeparatorHeight)],
  ]];

  return liner;
}

// Creates an instruction line with a checkmark icon followed by instruction text.
- (UIView*)createLineInstruction:(NSString*)instruction
                   checkmarkView:(UIView*)checkmarkView
                           index:(NSInteger)index {
  UILabel* instructionLabel = [[UILabel alloc] init];
  instructionLabel.textColor = [UIColor colorNamed:kGrey800Color];
  instructionLabel.font =
      [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];

  instructionLabel.attributedText =
      PutBoldPartInString(instruction, UIFontTextStyleSubheadline);
  instructionLabel.numberOfLines = 0;
  instructionLabel.adjustsFontForContentSizeCategory = YES;
  instructionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [instructionLabel
      setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh + 1
                                      forAxis:UILayoutConstraintAxisVertical];

  UIView* line = [[UIView alloc] init];
  [line addSubview:checkmarkView];
  [line addSubview:instructionLabel];

  // Add constraints for checkmarkView and instructionLabel vertical margins
  NSLayoutConstraint* minimumCheckmarkTopMargin =
      [checkmarkView.topAnchor constraintEqualToAnchor:line.topAnchor
                                              constant:kVerticalMargin];
  minimumCheckmarkTopMargin.priority = UILayoutPriorityDefaultHigh;
  NSLayoutConstraint* minimumCheckmarkBottomMargin =
      [checkmarkView.bottomAnchor constraintEqualToAnchor:line.bottomAnchor
                                                 constant:-kVerticalMargin];
  minimumCheckmarkBottomMargin.priority = UILayoutPriorityDefaultHigh;
  NSLayoutConstraint* minimumLabelTopMargin =
      [instructionLabel.topAnchor constraintEqualToAnchor:line.topAnchor
                                                 constant:kVerticalMargin];
  minimumLabelTopMargin.priority = UILayoutPriorityDefaultHigh;
  NSLayoutConstraint* minimumLabelBottomMargin =
      [instructionLabel.bottomAnchor constraintEqualToAnchor:line.bottomAnchor
                                                    constant:-kVerticalMargin];
  minimumLabelBottomMargin.priority = UILayoutPriorityDefaultHigh;

  [NSLayoutConstraint activateConstraints:@[
    [line.heightAnchor
        constraintGreaterThanOrEqualToConstant:kMinimumLineHeight],
    [checkmarkView.leadingAnchor constraintEqualToAnchor:line.leadingAnchor
                                                constant:kLeadingMargin],
    [checkmarkView.centerYAnchor constraintEqualToAnchor:line.centerYAnchor],
    [instructionLabel.leadingAnchor
        constraintEqualToAnchor:checkmarkView.trailingAnchor
                       constant:kSpacing],
    [instructionLabel.centerYAnchor constraintEqualToAnchor:line.centerYAnchor],
    minimumCheckmarkTopMargin, minimumCheckmarkBottomMargin,
    minimumLabelTopMargin, minimumLabelBottomMargin,
    [checkmarkView.bottomAnchor
        constraintLessThanOrEqualToAnchor:line.bottomAnchor
                                 constant:-kVerticalMargin],
    [checkmarkView.topAnchor
        constraintGreaterThanOrEqualToAnchor:line.topAnchor
                                    constant:kVerticalMargin],
    [instructionLabel.bottomAnchor
        constraintLessThanOrEqualToAnchor:line.bottomAnchor
                                 constant:-kVerticalMargin],
    [instructionLabel.topAnchor
        constraintGreaterThanOrEqualToAnchor:line.topAnchor
                                    constant:kVerticalMargin],
    [instructionLabel.trailingAnchor constraintEqualToAnchor:line.trailingAnchor
                                                    constant:-kTrailingMargin]
  ]];

  line.tag = index;
  line.accessibilityElements = @[ checkmarkView, instructionLabel ];
  return line;
}

// Creates a view with a green checkmark icon.
- (UIView*)createCheckmarkView {
  // Create checkmark image
  UIImageView* checkmarkImageView = [[UIImageView alloc] init];
  checkmarkImageView.translatesAutoresizingMaskIntoConstraints = NO;
  checkmarkImageView.contentMode = UIViewContentModeScaleAspectFit;

  // Use SF Symbol for checkmark
  UIImage* checkmarkImage = [UIImage systemImageNamed:@"checkmark"];
  checkmarkImageView.image = checkmarkImage;

  // Set green color (or use your brand color)
  checkmarkImageView.tintColor = [UIColor colorNamed:kGrey600Color];
  // Alternative brand colors:
  // checkmarkImageView.tintColor = [UIColor colorNamed:kBlue600Color];

  [NSLayoutConstraint activateConstraints:@[
    [checkmarkImageView.widthAnchor constraintEqualToConstant:kCheckmarkSize],
    [checkmarkImageView.heightAnchor constraintEqualToConstant:kCheckmarkSize],
  ]];

  // Create container view to match the width of the original number labels
  UIView* checkmarkContainer = [[UIView alloc] initWithFrame:CGRectZero];
  checkmarkContainer.translatesAutoresizingMaskIntoConstraints = NO;
  [checkmarkContainer addSubview:checkmarkImageView];

  [NSLayoutConstraint activateConstraints:@[
    [checkmarkImageView.centerYAnchor
        constraintEqualToAnchor:checkmarkContainer.centerYAnchor],
    [checkmarkImageView.centerXAnchor
        constraintEqualToAnchor:checkmarkContainer.centerXAnchor],
    [checkmarkContainer.widthAnchor
        constraintEqualToConstant:kCheckmarkContainerWidth],
    [checkmarkContainer.heightAnchor
        constraintEqualToAnchor:checkmarkImageView.heightAnchor],
  ]];

  return checkmarkContainer;
}

@end