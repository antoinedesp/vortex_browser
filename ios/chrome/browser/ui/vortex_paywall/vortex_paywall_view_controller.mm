#import "ios/chrome/browser/ui/vortex_paywall/vortex_paywall_view_controller.h"

#import <QuartzCore/QuartzCore.h>

#import "base/strings/sys_string_conversions.h"
#import "ios/chrome/browser/shared/model/url/chrome_url_constants.h"
#import "ios/chrome/browser/shared/ui/util/uikit_ui_util.h"        // nogncheck
#import "ios/chrome/browser/ui/vortex_paywall/vortex_paywall_item.h"
#import "ios/chrome/common/ui/colors/semantic_color_names.h"
#import "ios/chrome/grit/ios_strings.h"
#import "ui/base/l10n/l10n_util.h"

@interface VortexPaywallViewController ()

// Spinner + layout.
@property(nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property(nonatomic, strong) UIStackView* stackView;
@property(nonatomic, strong) UIScrollView* scrollView;

// Static sections.
@property(nonatomic, strong) UILabel* termsLabel;
@property(nonatomic, strong) UIView* perksCard;
@property(nonatomic, strong) UIView* heroView;
@property(nonatomic, strong) UIView* valuePropositionCard;

// Floating CTA.
@property(nonatomic, strong) UIView* bottomBar;
@property(nonatomic, strong) UIButton* primaryButton;
@property(nonatomic, strong) UILabel* trialDetailsLabel;
@property(nonatomic, strong) CAGradientLayer* primaryGradientLayer;

// Footer links.
@property(nonatomic, strong) UIView* footerView;

// Current products and selection.
@property(nonatomic, copy) NSArray<VortexPaywallPackageItem*>* products;
@property(nonatomic, assign) NSInteger selectedIndex;

@end

@implementation VortexPaywallViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  NSLog(@"[VortexPaywallViewController] viewDidLoad");

  self.view.backgroundColor = [UIColor colorNamed:kSecondaryBackgroundColor];
  self.title = l10n_util::GetNSString(IDS_IOS_VORTEX_PLUS_TITLE);
  self.selectedIndex = -1;

  self.navigationItem.leftBarButtonItem =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                    target:self
                                                    action:@selector(closeTapped)];

  [self setUpLayout];

  if (self.products.count == 0) {
    [self showLoading];
  } else {
    [self showPackages:self.products];
  }
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

  // Update gradient frame when layout changes.
  self.primaryGradientLayer.frame = self.bottomBar.bounds;
}

#pragma mark - Layout

- (void)setUpLayout {
  // Scroll area.
  UIScrollView* scrollView =
      [[UIScrollView alloc] initWithFrame:self.view.bounds];
  scrollView.translatesAutoresizingMaskIntoConstraints = NO;
  scrollView.alwaysBounceVertical = YES;
  [self.view addSubview:scrollView];
  self.scrollView = scrollView;

  UIStackView* stack = [[UIStackView alloc] initWithFrame:CGRectZero];
  stack.axis = UILayoutConstraintAxisVertical;
  stack.spacing = 20.0;
  stack.alignment = UIStackViewAlignmentFill;
  stack.translatesAutoresizingMaskIntoConstraints = NO;
  [scrollView addSubview:stack];
  self.stackView = stack;

  UILayoutGuide* safe = self.view.safeAreaLayoutGuide;

  [NSLayoutConstraint activateConstraints:@[
    [scrollView.topAnchor constraintEqualToAnchor:safe.topAnchor],
    [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

    [stack.topAnchor constraintEqualToAnchor:scrollView.topAnchor constant:24.0],
    [stack.leadingAnchor constraintEqualToAnchor:scrollView.leadingAnchor constant:24.0],
    [stack.trailingAnchor constraintEqualToAnchor:scrollView.trailingAnchor constant:-24.0],
    [stack.bottomAnchor constraintEqualToAnchor:scrollView.bottomAnchor constant:-120.0],
    [stack.widthAnchor constraintEqualToAnchor:scrollView.widthAnchor constant:-48.0],
  ]];

  // Hero icon.
  [self.stackView addArrangedSubview:[self createHeroView]];

  // Description with emotional value.
  UILabel* subtitleLabel = [[UILabel alloc] init];
  subtitleLabel.text = l10n_util::GetNSString(IDS_IOS_VORTEX_PLUS_SUBTITLE);
  subtitleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
  subtitleLabel.textColor = [UIColor secondaryLabelColor];
  subtitleLabel.numberOfLines = 0;
  subtitleLabel.textAlignment = NSTextAlignmentCenter;

  [self.stackView addArrangedSubview:subtitleLabel];

  // Value proposition card.
  [self.stackView addArrangedSubview:[self createValuePropositionCard]];

  // Spinner while loading products.
  UIActivityIndicatorView* spinner =
      [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
  spinner.hidesWhenStopped = YES;
  spinner.tag = 500;
  self.activityIndicator = spinner;
  [self.stackView addArrangedSubview:spinner];

  // Floating gradient CTA at bottom.
  [self setUpBottomBar];

  // Footer links.
  [self setUpFooter];
}

- (UIView*)createHeroView {
  UIView* container = [[UIView alloc] initWithFrame:CGRectZero];
  container.translatesAutoresizingMaskIntoConstraints = NO;

  // Gradient circle background.
//  UIView* circleView = [[UIView alloc] initWithFrame:CGRectZero];
//  circleView.translatesAutoresizingMaskIntoConstraints = NO;
//  circleView.layer.cornerRadius = 50.0;
//  circleView.clipsToBounds = YES;
//  [container addSubview:circleView];
//
//  CAGradientLayer* gradient = [CAGradientLayer layer];
//  gradient.colors = @[
//    (id)[UIColor colorNamed:kBlueColor].CGColor,
//    (id)[UIColor colorNamed:kBlueColor].CGColor,
//  ];
//  gradient.startPoint = CGPointMake(0.0, 0.0);
//  gradient.endPoint = CGPointMake(1.0, 1.0);
//  gradient.frame = CGRectMake(0, 0, 100, 100);
//  [circleView.layer insertSublayer:gradient atIndex:0];

//  // Shield icon.
//  UIImageSymbolConfiguration* config =
//      [UIImageSymbolConfiguration configurationWithPointSize:48
//                                                      weight:UIImageSymbolWeightSemibold];
//  UIImage* shieldImage = [UIImage systemImageNamed:@"shield.lefthalf.filled"
//                                      withConfiguration:config];
//  UIImageView* shieldIcon = [[UIImageView alloc] initWithImage:shieldImage];
//  shieldIcon.tintColor = [UIColor whiteColor];
//  shieldIcon.contentMode = UIViewContentModeScaleAspectFit;
//  shieldIcon.translatesAutoresizingMaskIntoConstraints = NO;
//  [circleView addSubview:shieldIcon];
//
//  [NSLayoutConstraint activateConstraints:@[
//    [circleView.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
//    [circleView.topAnchor constraintEqualToAnchor:container.topAnchor],
//    [circleView.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
//    [circleView.widthAnchor constraintEqualToConstant:100.0],
//    [circleView.heightAnchor constraintEqualToConstant:100.0],
//
//    [shieldIcon.centerXAnchor constraintEqualToAnchor:circleView.centerXAnchor],
//    [shieldIcon.centerYAnchor constraintEqualToAnchor:circleView.centerYAnchor],
//    [shieldIcon.widthAnchor constraintEqualToConstant:52.0],
//    [shieldIcon.heightAnchor constraintEqualToConstant:52.0],
//  ]];

  // Update gradient frame on layout.
//  dispatch_async(dispatch_get_main_queue(), ^{
//    gradient.frame = circleView.bounds;
//  });

  self.heroView = container;
  return container;
}

- (UIView*)createValuePropositionCard {
  UIView* card = [[UIView alloc] initWithFrame:CGRectZero];
  card.translatesAutoresizingMaskIntoConstraints = NO;
  card.backgroundColor = [UIColor colorNamed:kSecondaryBackgroundColor];
  card.layer.cornerRadius = 18.0;
  card.layer.borderWidth = 1.0;
  card.layer.borderColor = [UIColor systemGray5Color].CGColor;

  UIStackView* vertical = [[UIStackView alloc] initWithFrame:CGRectZero];
  vertical.axis = UILayoutConstraintAxisVertical;
  vertical.alignment = UIStackViewAlignmentFill;
  vertical.spacing = 12.0;
  vertical.translatesAutoresizingMaskIntoConstraints = NO;
  [card addSubview:vertical];

  [NSLayoutConstraint activateConstraints:@[
    [vertical.topAnchor constraintEqualToAnchor:card.topAnchor constant:20.0],
    [vertical.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20.0],
    [vertical.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20.0],
    [vertical.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20.0],
  ]];

  // Header.
  UILabel* header = [[UILabel alloc] init];
  header.text = l10n_util::GetNSString(IDS_IOS_VORTEX_PLUS_FEATURES_HEADER);
  header.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
  header.textAlignment = NSTextAlignmentCenter;
  [vertical addArrangedSubview:header];

  // Divider.
  UIView* divider = [[UIView alloc] initWithFrame:CGRectZero];
  divider.backgroundColor = [UIColor systemGray5Color];
  divider.translatesAutoresizingMaskIntoConstraints = NO;
  [divider.heightAnchor constraintEqualToConstant:1.0].active = YES;
  [vertical addArrangedSubview:divider];

  // Benefits.
  NSArray<NSDictionary*>* benefits = @[
    @{@"icon": @"lock.shield.fill", @"text": l10n_util::GetNSString(IDS_IOS_VORTEX_PLUS_FEATURE_VPN)},
    @{@"icon": @"nosign", @"text": l10n_util::GetNSString(IDS_IOS_VORTEX_PLUS_FEATURE_AD_FREE)},
    @{@"icon": @"bolt.fill", @"text": l10n_util::GetNSString(IDS_IOS_VORTEX_PLUS_FEATURE_TURBO)},
    @{@"icon": @"hand.raised.fill", @"text": l10n_util::GetNSString(IDS_IOS_VORTEX_PLUS_FEATURE_PRIVACY)},
    @{@"icon": @"checkmark.shield.fill", @"text": l10n_util::GetNSString(IDS_IOS_VORTEX_PLUS_FEATURE_SECURE)},
  ];

  for (NSDictionary* benefit in benefits) {
    [vertical addArrangedSubview:[self benefitRowWithIcon:benefit[@"icon"]
                                                     text:benefit[@"text"]]];
  }

  self.valuePropositionCard = card;
  return card;
}

- (UIView*)benefitRowWithIcon:(NSString*)iconName text:(NSString*)text {
  UIStackView* row = [[UIStackView alloc] initWithFrame:CGRectZero];
  row.axis = UILayoutConstraintAxisHorizontal;
  row.alignment = UIStackViewAlignmentCenter;
  row.spacing = 12.0;
  row.translatesAutoresizingMaskIntoConstraints = NO;

  UIImageSymbolConfiguration* config =
      [UIImageSymbolConfiguration configurationWithPointSize:16
                                                      weight:UIImageSymbolWeightMedium];
  UIImage* icon = [UIImage systemImageNamed:iconName withConfiguration:config];
  UIImageView* imageView = [[UIImageView alloc] initWithImage:icon];
  imageView.tintColor = [UIColor colorNamed:kBrandPurpleColor];
  imageView.contentMode = UIViewContentModeScaleAspectFit;
  imageView.translatesAutoresizingMaskIntoConstraints = NO;
  [imageView.widthAnchor constraintEqualToConstant:20.0].active = YES;

  UILabel* label = [[UILabel alloc] init];
  label.text = text;
  label.font = [UIFont systemFontOfSize:15.0];
  label.numberOfLines = 0;

  [row addArrangedSubview:imageView];
  [row addArrangedSubview:label];

  return row;
}

- (void)setUpBottomBar {
  UIView* bottomBar = [[UIView alloc] initWithFrame:CGRectZero];
  bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
  bottomBar.layer.cornerRadius = 22.0;
  bottomBar.layer.masksToBounds = YES;
  [self.view addSubview:bottomBar];
  self.bottomBar = bottomBar;

  UILayoutGuide* safe = self.view.safeAreaLayoutGuide;

  [NSLayoutConstraint activateConstraints:@[
    [bottomBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
    [bottomBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],
    [bottomBar.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-80.0],
    [bottomBar.heightAnchor constraintEqualToConstant:56.0],
  ]];

  // Solid background color.
  bottomBar.backgroundColor = [UIColor colorNamed:kBrandPurpleColor];

  UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  [button setTitle:l10n_util::GetNSString(IDS_IOS_VORTEX_PLUS_FREE_TRIAL_BUTTON)
          forState:UIControlStateNormal];
  button.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
  [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  button.backgroundColor = [UIColor clearColor];
  [button addTarget:self
             action:@selector(primaryButtonTapped)
   forControlEvents:UIControlEventTouchUpInside];

  [bottomBar addSubview:button];
  self.primaryButton = button;

  [NSLayoutConstraint activateConstraints:@[
    [button.topAnchor constraintEqualToAnchor:bottomBar.topAnchor],
    [button.bottomAnchor constraintEqualToAnchor:bottomBar.bottomAnchor],
    [button.leadingAnchor constraintEqualToAnchor:bottomBar.leadingAnchor],
    [button.trailingAnchor constraintEqualToAnchor:bottomBar.trailingAnchor],
  ]];

  // Trial details label below button.
  UILabel* detailsLabel = [[UILabel alloc] init];
  detailsLabel.text = l10n_util::GetNSStringF(IDS_IOS_VORTEX_PLUS_TRIAL_DETAILS,
                                               u"$39.99/year");
  detailsLabel.font = [UIFont systemFontOfSize:13.0];
  detailsLabel.textColor = [UIColor secondaryLabelColor];
  detailsLabel.textAlignment = NSTextAlignmentCenter;
  detailsLabel.numberOfLines = 0;
  detailsLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:detailsLabel];
  self.trialDetailsLabel = detailsLabel;

  [NSLayoutConstraint activateConstraints:@[
    [detailsLabel.topAnchor constraintEqualToAnchor:bottomBar.bottomAnchor constant:8.0],
    [detailsLabel.leadingAnchor constraintEqualToAnchor:bottomBar.leadingAnchor],
    [detailsLabel.trailingAnchor constraintEqualToAnchor:bottomBar.trailingAnchor],
  ]];
}

- (void)setUpFooter {
  UIView* footer = [[UIView alloc] initWithFrame:CGRectZero];
  footer.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:footer];
  self.footerView = footer;

  UILayoutGuide* safe = self.view.safeAreaLayoutGuide;

  [NSLayoutConstraint activateConstraints:@[
    [footer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
    [footer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],
    [footer.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-16.0],
    [footer.heightAnchor constraintEqualToConstant:20.0],
  ]];

  // Restore button (left).
  UIButton* restoreButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [restoreButton setTitle:l10n_util::GetNSString(IDS_IOS_VORTEX_PLUS_RESTORE_PURCHASES)
                 forState:UIControlStateNormal];
  restoreButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
  [restoreButton setTitleColor:[UIColor colorNamed:kBrandPurpleColor]
                      forState:UIControlStateNormal];
  [restoreButton addTarget:self
                    action:@selector(restoreTapped)
          forControlEvents:UIControlEventTouchUpInside];
  restoreButton.translatesAutoresizingMaskIntoConstraints = NO;
  [footer addSubview:restoreButton];

  // Legal links (right).
  UIStackView* legalStack = [[UIStackView alloc] initWithFrame:CGRectZero];
  legalStack.axis = UILayoutConstraintAxisHorizontal;
  legalStack.spacing = 8.0;
  legalStack.translatesAutoresizingMaskIntoConstraints = NO;
  [footer addSubview:legalStack];

  UIButton* termsButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [termsButton setTitle:l10n_util::GetNSString(IDS_IOS_VORTEX_PLUS_TERMS)
               forState:UIControlStateNormal];
  termsButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
  [termsButton setTitleColor:[UIColor colorNamed:kBrandPurpleColor]
                    forState:UIControlStateNormal];
  [termsButton addTarget:self
                  action:@selector(termsTapped)
        forControlEvents:UIControlEventTouchUpInside];

  UILabel* separator = [[UILabel alloc] init];
  separator.text = @"·";
  separator.font = [UIFont systemFontOfSize:12.0];
  separator.textColor = [UIColor colorNamed:kBrandPurpleColor];

  UIButton* privacyButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [privacyButton setTitle:l10n_util::GetNSString(IDS_IOS_VORTEX_PLUS_PRIVACY)
                 forState:UIControlStateNormal];
  privacyButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
  [privacyButton setTitleColor:[UIColor colorNamed:kBrandPurpleColor]
                      forState:UIControlStateNormal];
  [privacyButton addTarget:self
                    action:@selector(privacyTapped)
          forControlEvents:UIControlEventTouchUpInside];

  [legalStack addArrangedSubview:termsButton];
  [legalStack addArrangedSubview:separator];
  [legalStack addArrangedSubview:privacyButton];

  [NSLayoutConstraint activateConstraints:@[
    [restoreButton.leadingAnchor constraintEqualToAnchor:footer.leadingAnchor],
    [restoreButton.centerYAnchor constraintEqualToAnchor:footer.centerYAnchor],

    [legalStack.trailingAnchor constraintEqualToAnchor:footer.trailingAnchor],
    [legalStack.centerYAnchor constraintEqualToAnchor:footer.centerYAnchor],
  ]];
}

#pragma mark - Actions

- (void)closeTapped {
  [self.delegate vortexPaywallViewControllerDidRequestClose:self];
}

- (void)primaryButtonTapped {
  if (self.products.count == 0) {
    return;
  }
  NSInteger index = self.selectedIndex;
  if (index < 0 || index >= (NSInteger)self.products.count) {
    index = 0;
  }
  VortexPaywallPackageItem* item = self.products[index];
  [self.delegate vortexPaywallViewController:self
                        didSelectPackageIdentifier:item.identifier];
}

- (void)optionTapped:(UITapGestureRecognizer*)recognizer {
  UIView* view = recognizer.view;
  if (!view) {
    return;
  }
  NSInteger idx = view.tag - 1000;
  if (idx < 0 || idx >= (NSInteger)self.products.count) {
    return;
  }
  self.selectedIndex = idx;
  [self refreshOptionSelectionUI];
  [self updateTrialDetailsForSelection];
}

- (void)restoreTapped {
  NSLog(@"[VortexPaywallViewController] Restore purchases tapped");
  [self.delegate vortexPaywallViewControllerDidRequestRestore:self];
}

- (void)termsTapped {
  NSLog(@"[VortexPaywallViewController] Terms tapped");
  [[UIApplication sharedApplication]
      openURL:[NSURL URLWithString:[NSString stringWithUTF8String:kTermsOfServiceURL]]
      options:@{}
      completionHandler:nil];
}

- (void)privacyTapped {
  NSLog(@"[VortexPaywallViewController] Privacy tapped");
  [[UIApplication sharedApplication]
      openURL:[NSURL URLWithString:[NSString stringWithUTF8String:kPrivacyLearnMoreURL]]
      options:@{}
      completionHandler:nil];
}

#pragma mark - VortexPaywallConsumer

- (void)showLoading {
  NSLog(@"[VortexPaywallViewController] showLoading");
  [self.activityIndicator startAnimating];
  [self clearDynamicViews];
}

- (void)stopLoading {
  NSLog(@"[VortexPaywallViewController] stopLoading");
  [self.activityIndicator stopAnimating];
  [self.stackView setNeedsLayout];
  [self.scrollView setNeedsLayout];
}

- (void)showPackages:(NSArray<VortexPaywallPackageItem*>*)products {
  NSLog(@"[VortexPaywallViewController] showPackages: %lu products",
        (unsigned long)products.count);

  self.products = products;
  [self.activityIndicator stopAnimating];

  if (self.activityIndicator.superview == self.stackView) {
    [self.stackView removeArrangedSubview:self.activityIndicator];
    [self.activityIndicator removeFromSuperview];
  }

  [self clearDynamicViews];

  // Choose default selection: recommended first, otherwise most expensive.
  NSInteger defaultIndex = -1;
  for (NSUInteger i = 0; i < products.count; ++i) {
    if (products[i].recommended) {
      defaultIndex = (NSInteger)i;
      break;
    }
  }
  if (defaultIndex < 0 && products.count > 0) {
    defaultIndex = (NSInteger)products.count - 1;
  }
  self.selectedIndex = defaultIndex;

  // Create option tiles.
  [products enumerateObjectsUsingBlock:^(VortexPaywallPackageItem* item,
                                         NSUInteger idx,
                                         BOOL* stop) {
    UIView* option = [self optionViewForItem:item index:idx];
    option.tag = 1000 + idx;
    [self.stackView addArrangedSubview:option];
  }];

  [self ensureTermsLabel];
  [self refreshOptionSelectionUI];
  [self updateTrialDetailsForSelection];
}

- (void)showErrorMessage:(NSString*)message {
  NSLog(@"[VortexPaywallViewController] showErrorMessage: %@", message);

  [self.activityIndicator stopAnimating];
  [self clearDynamicViews];

  UILabel* label = [[UILabel alloc] init];
  label.text = message;
  label.font = [UIFont systemFontOfSize:14.0];
  label.textColor = [UIColor systemRedColor];
  label.numberOfLines = 0;
  label.textAlignment = NSTextAlignmentCenter;
  label.tag = 999;

  [self.stackView addArrangedSubview:label];
}

#pragma mark - Helpers (dynamic views)

- (void)clearDynamicViews {
  NSMutableArray<UIView*>* toRemove = [NSMutableArray array];
  for (UIView* v in self.stackView.arrangedSubviews) {
    if (v.tag == 999 || (v.tag >= 1000 && v.tag < 2000)) {
      [toRemove addObject:v];
    }
  }
  for (UIView* v in toRemove) {
    [self.stackView removeArrangedSubview:v];
    [v removeFromSuperview];
  }
}

- (UIView*)optionViewForItem:(VortexPaywallPackageItem*)item
                       index:(NSUInteger)index {
  UIView* card = [[UIView alloc] initWithFrame:CGRectZero];
  card.translatesAutoresizingMaskIntoConstraints = NO;
  card.backgroundColor = [UIColor colorNamed:kSecondaryBackgroundColor];
  card.layer.cornerRadius = 18.0;
  card.layer.borderWidth = 2.0;
  card.layer.borderColor = [UIColor systemGray5Color].CGColor;

  UITapGestureRecognizer* tap =
      [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(optionTapped:)];
  [card addGestureRecognizer:tap];

  UIStackView* horizontal =
      [[UIStackView alloc] initWithFrame:CGRectZero];
  horizontal.axis = UILayoutConstraintAxisHorizontal;
  horizontal.alignment = UIStackViewAlignmentCenter;
  horizontal.spacing = 12.0;
  horizontal.translatesAutoresizingMaskIntoConstraints = NO;
  [card addSubview:horizontal];

  [NSLayoutConstraint activateConstraints:@[
    [horizontal.topAnchor constraintEqualToAnchor:card.topAnchor constant:14.0],
    [horizontal.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16.0],
    [horizontal.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16.0],
    [horizontal.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14.0],
  ]];

  // Radio circle.
//  UIView* circle = [[UIView alloc] initWithFrame:CGRectZero];
//  circle.translatesAutoresizingMaskIntoConstraints = NO;
//  circle.layer.cornerRadius = 14.0;
//  circle.layer.borderWidth = 2.0;
//  circle.layer.borderColor = [UIColor systemPinkColor].CGColor;
//  circle.tag = 10;

//  [NSLayoutConstraint activateConstraints:@[
//    [circle.widthAnchor constraintEqualToConstant:28.0],
//    [circle.heightAnchor constraintEqualToConstant:28.0],
//  ]];

//  [horizontal addArrangedSubview:circle];

  // Title + subtitle.
  UIStackView* textStack =
      [[UIStackView alloc] initWithFrame:CGRectZero];
  textStack.axis = UILayoutConstraintAxisVertical;
  textStack.alignment = UIStackViewAlignmentLeading;
  textStack.spacing = 2.0;
  textStack.translatesAutoresizingMaskIntoConstraints = NO;

  UILabel* title = [[UILabel alloc] init];
  title.text = item.title;
  title.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];

  UILabel* subtitle = [[UILabel alloc] init];
  subtitle.text = item.subtitle;
  subtitle.font = [UIFont systemFontOfSize:13.0];
  subtitle.textColor = [UIColor secondaryLabelColor];
  subtitle.numberOfLines = 1;

  [textStack addArrangedSubview:title];
  [textStack addArrangedSubview:subtitle];

  [horizontal addArrangedSubview:textStack];

  // Badge for recommended.
  if (item.recommended) {
//    UILabel* badge = [[UILabel alloc] init];
//    badge.text = @"BEST VALUE";
//    badge.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightBold];
//    badge.textColor = [UIColor colorNamed:kTextSecondaryColor];
////    badge.backgroundColor = [UIColor colorNamed:kTextSecondaryColor];
//    badge.textAlignment = NSTextAlignmentCenter;
//    badge.layer.cornerRadius = 8.0;
//    badge.clipsToBounds = YES;
//    badge.translatesAutoresizingMaskIntoConstraints = NO;
//    [card addSubview:badge];
//
//    [NSLayoutConstraint activateConstraints:@[
//        // Width and height
//        [badge.heightAnchor constraintEqualToConstant:22.0],
//        [badge.widthAnchor constraintGreaterThanOrEqualToConstant:80.0],
//
//        // Position badge 24 px from right, centered vertically
//        [badge.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-12.0],
//
//        // Vertical: overflow the top border by half badge height (11px)
//        [badge.centerYAnchor constraintEqualToAnchor:card.topAnchor constant:11.0]
//
//    ]];
  }

    // Spacer.
  UIView* spacer = [[UIView alloc] initWithFrame:CGRectZero];
  spacer.translatesAutoresizingMaskIntoConstraints = NO;
  [horizontal addArrangedSubview:spacer];
  [spacer.widthAnchor constraintGreaterThanOrEqualToConstant:10.0].active = YES;

  // Price label.
  UILabel* priceLabel = [[UILabel alloc] init];
  priceLabel.text = item.priceString ?: @"";
  priceLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
  priceLabel.textAlignment = NSTextAlignmentRight;
  priceLabel.textColor = [UIColor labelColor];
  priceLabel.translatesAutoresizingMaskIntoConstraints = NO;
  priceLabel.tag = 20; // For later lookup during selection state updates.
  [horizontal addArrangedSubview:priceLabel];

  // Tag the card for dynamic removal.
  card.tag = 1000 + index;
  return card;
}

- (void)refreshOptionSelectionUI {
  for (UIView* v in self.stackView.arrangedSubviews) {
    if (v.tag < 1000 || v.tag >= 2000) continue;

    NSInteger idx = v.tag - 1000;
    BOOL selected = (idx == self.selectedIndex);

    UIView* circle = [v viewWithTag:10];
    UILabel* priceLabel = (UILabel*)[v viewWithTag:20];

    if (selected) {
      v.layer.borderColor = [UIColor colorNamed:kBrandPurpleColor].CGColor;
      circle.backgroundColor = [UIColor colorNamed:kBrandPurpleColor];
      priceLabel.textColor = [UIColor colorNamed:kBrandPurpleColor];
      circle.layer.borderWidth = 2.0;
    } else {
      v.layer.borderColor = [UIColor systemGray5Color].CGColor;
      circle.backgroundColor = [UIColor clearColor];
      priceLabel.textColor = [UIColor labelColor];
      circle.layer.borderWidth = 2.0;
    }
  }
}

- (void)updateTrialDetailsForSelection {
  if (self.selectedIndex < 0 || self.selectedIndex >= (NSInteger)self.products.count) {
    return;
  }

  VortexPaywallPackageItem* item = self.products[self.selectedIndex];

  // Update the button title.
  if (item.hasTrial) {
    [self.primaryButton setTitle:l10n_util::GetNSString(IDS_IOS_VORTEX_PLUS_FREE_TRIAL_BUTTON)
                        forState:UIControlStateNormal];
  } else {
    [self.primaryButton setTitle:l10n_util::GetNSString(IDS_IOS_VORTEX_PLUS_CONTINUE_BUTTON)
                        forState:UIControlStateNormal];
  }

  // Trial details text.
  if (item.hasTrial) {
    self.trialDetailsLabel.text = l10n_util::GetNSStringF(
        IDS_IOS_VORTEX_PLUS_TRIAL_DETAILS,
        base::SysNSStringToUTF16(item.priceString));
  } else {
    self.trialDetailsLabel.text = l10n_util::GetNSStringF(
        IDS_IOS_VORTEX_PLUS_PRICE_DETAILS,
        base::SysNSStringToUTF16(item.priceString));
  }
}

- (void)ensureTermsLabel {
  if (self.termsLabel) return;

  UILabel* label = [[UILabel alloc] init];
  label.font = [UIFont systemFontOfSize:13.0];
  label.textColor = [UIColor secondaryLabelColor];
  label.textAlignment = NSTextAlignmentCenter;
  label.numberOfLines = 0;
  label.text = l10n_util::GetNSString(IDS_IOS_VORTEX_PLUS_SUBSCRIPTION_TERMS);

  self.termsLabel = label;
  [self.stackView addArrangedSubview:label];
}
@end