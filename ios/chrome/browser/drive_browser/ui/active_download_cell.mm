// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/drive_browser/ui/active_download_cell.h"

#import "ios/chrome/browser/drive_browser/model/active_download_item.h"
#import "ios/chrome/browser/shared/ui/symbols/symbols.h"

namespace {

// Layout constants.
const CGFloat kIconSize = 40.0;
const CGFloat kCancelButtonSize = 44.0;
const CGFloat kHorizontalPadding = 16.0;
const CGFloat kVerticalPadding = 12.0;
const CGFloat kProgressBarHeight = 4.0;
const CGFloat kLabelSpacing = 4.0;

}  // namespace

NSString* const kActiveDownloadCellReuseIdentifier = @"ActiveDownloadCell";

@implementation ActiveDownloadCell {
  UIImageView* _iconView;
  UILabel* _fileNameLabel;
  UILabel* _progressTextLabel;
  UIProgressView* _progressView;
  UIButton* _cancelButton;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString*)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self setupViews];
  }
  return self;
}

- (void)setupViews {
  self.selectionStyle = UITableViewCellSelectionStyleNone;

  // Icon view.
  _iconView = [[UIImageView alloc] init];
  _iconView.translatesAutoresizingMaskIntoConstraints = NO;
  _iconView.contentMode = UIViewContentModeScaleAspectFit;
  _iconView.tintColor = [UIColor systemBlueColor];
  [self.contentView addSubview:_iconView];

  // File name label.
  _fileNameLabel = [[UILabel alloc] init];
  _fileNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _fileNameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
  _fileNameLabel.textColor = [UIColor labelColor];
  _fileNameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
  [self.contentView addSubview:_fileNameLabel];

  // Progress text label.
  _progressTextLabel = [[UILabel alloc] init];
  _progressTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _progressTextLabel.font =
      [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
  _progressTextLabel.textColor = [UIColor secondaryLabelColor];
  [self.contentView addSubview:_progressTextLabel];

  // Progress view.
  _progressView = [[UIProgressView alloc]
      initWithProgressViewStyle:UIProgressViewStyleDefault];
  _progressView.translatesAutoresizingMaskIntoConstraints = NO;
  _progressView.progressTintColor = [UIColor systemBlueColor];
  _progressView.trackTintColor = [UIColor systemGray5Color];
  [self.contentView addSubview:_progressView];

  // Cancel button.
  _cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
  _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
  UIImage* cancelImage =
      DefaultSymbolWithPointSize(@"xmark.circle.fill", 22.0);
  [_cancelButton setImage:cancelImage forState:UIControlStateNormal];
  _cancelButton.tintColor = [UIColor systemGray3Color];
  [_cancelButton addTarget:self
                    action:@selector(cancelButtonTapped)
          forControlEvents:UIControlEventTouchUpInside];
  [self.contentView addSubview:_cancelButton];

  // Layout constraints.
  [NSLayoutConstraint activateConstraints:@[
    // Icon view.
    [_iconView.leadingAnchor
        constraintEqualToAnchor:self.contentView.leadingAnchor
                       constant:kHorizontalPadding],
    [_iconView.centerYAnchor
        constraintEqualToAnchor:self.contentView.centerYAnchor],
    [_iconView.widthAnchor constraintEqualToConstant:kIconSize],
    [_iconView.heightAnchor constraintEqualToConstant:kIconSize],

    // Cancel button.
    [_cancelButton.trailingAnchor
        constraintEqualToAnchor:self.contentView.trailingAnchor
                       constant:-kHorizontalPadding],
    [_cancelButton.centerYAnchor
        constraintEqualToAnchor:self.contentView.centerYAnchor],
    [_cancelButton.widthAnchor constraintEqualToConstant:kCancelButtonSize],
    [_cancelButton.heightAnchor constraintEqualToConstant:kCancelButtonSize],

    // File name label.
    [_fileNameLabel.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor
                                                 constant:kHorizontalPadding],
    [_fileNameLabel.trailingAnchor
        constraintEqualToAnchor:_cancelButton.leadingAnchor
                       constant:-kHorizontalPadding],
    [_fileNameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor
                                             constant:kVerticalPadding],

    // Progress text label.
    [_progressTextLabel.leadingAnchor
        constraintEqualToAnchor:_fileNameLabel.leadingAnchor],
    [_progressTextLabel.trailingAnchor
        constraintEqualToAnchor:_fileNameLabel.trailingAnchor],
    [_progressTextLabel.topAnchor
        constraintEqualToAnchor:_fileNameLabel.bottomAnchor
                       constant:kLabelSpacing],

    // Progress view.
    [_progressView.leadingAnchor
        constraintEqualToAnchor:_fileNameLabel.leadingAnchor],
    [_progressView.trailingAnchor
        constraintEqualToAnchor:_fileNameLabel.trailingAnchor],
    [_progressView.topAnchor constraintEqualToAnchor:_progressTextLabel.bottomAnchor
                                            constant:kLabelSpacing],
    [_progressView.heightAnchor constraintEqualToConstant:kProgressBarHeight],
    [_progressView.bottomAnchor
        constraintEqualToAnchor:self.contentView.bottomAnchor
                       constant:-kVerticalPadding],
  ]];
}

- (void)configureWithItem:(ActiveDownloadItem*)item {
  _fileNameLabel.text = item.fileName;
  _progressView.progress = item.progress;
  _progressTextLabel.text = [item progressString];

  // Set icon based on download type.
  UIImage* icon = nil;
  UIColor* tintColor = [UIColor systemBlueColor];

  switch (item.downloadType) {
    case ActiveDownloadTypeImage:
      icon = DefaultSymbolWithPointSize(@"photo.fill", 24.0);
      tintColor = [UIColor systemBlueColor];
      break;
    case ActiveDownloadTypeVideo:
      icon = DefaultSymbolWithPointSize(@"video.fill", 24.0);
      tintColor = [UIColor systemPurpleColor];
      break;
    case ActiveDownloadTypeFile:
      icon = DefaultSymbolWithPointSize(@"doc.fill", 24.0);
      tintColor = [UIColor systemGrayColor];
      break;
  }

  _iconView.image = icon;
  _iconView.tintColor = tintColor;

  // Update cancel button visibility.
  _cancelButton.hidden = ![item isCancellable];

  // Update progress text based on state.
  switch (item.state) {
    case ActiveDownloadStateInProgress:
      _progressTextLabel.text = [item progressString];
      _progressView.hidden = NO;
      break;
    case ActiveDownloadStateComplete:
      _progressTextLabel.text = @"Complete";
      _progressView.hidden = YES;
      break;
    case ActiveDownloadStateFailed:
      _progressTextLabel.text = @"Failed";
      _progressTextLabel.textColor = [UIColor systemRedColor];
      _progressView.hidden = YES;
      break;
    case ActiveDownloadStateCancelled:
      _progressTextLabel.text = @"Cancelled";
      _progressView.hidden = YES;
      break;
  }
}

- (void)updateProgress:(float)progress {
  _progressView.progress = progress;
}

- (void)updateProgressText:(NSString*)progressText {
  _progressTextLabel.text = progressText;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  _fileNameLabel.text = nil;
  _progressTextLabel.text = nil;
  _progressTextLabel.textColor = [UIColor secondaryLabelColor];
  _progressView.progress = 0.0;
  _progressView.hidden = NO;
  _cancelButton.hidden = NO;
  self.cancelHandler = nil;
}

#pragma mark - Private

- (void)cancelButtonTapped {
  if (self.cancelHandler) {
    self.cancelHandler();
  }
}

@end
