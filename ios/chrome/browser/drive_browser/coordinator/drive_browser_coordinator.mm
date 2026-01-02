// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/drive_browser/coordinator/drive_browser_coordinator.h"

#import <QuickLook/QuickLook.h>

#import "base/strings/sys_string_conversions.h"
#import "components/strings/grit/components_strings.h"
#import "ios/chrome/browser/download/coordinator/download_file_preview_coordinator.h"
#import "ios/chrome/browser/drive_browser/coordinator/drive_browser_mediator.h"
#import "ios/chrome/browser/drive_browser/coordinator/drive_browser_mediator_delegate.h"
#import "ios/chrome/browser/drive_browser/model/drive_browser_service.h"
#import "ios/chrome/browser/drive_browser/model/drive_browser_service_factory.h"
#import "ios/chrome/browser/drive_browser/ui/drive_browser_table_view_controller.h"
#import "ios/chrome/browser/shared/model/browser/browser.h"
#import "ios/chrome/browser/shared/model/profile/profile_ios.h"
#import "ios/chrome/browser/shared/model/utils/mime_type_util.h"
#import "ios/chrome/browser/shared/public/commands/application_commands.h"
#import "ios/chrome/browser/shared/public/commands/command_dispatcher.h"
#import "ios/chrome/browser/shared/public/commands/open_new_tab_command.h"
#import "ios/chrome/grit/ios_strings.h"
#import "ios/web/public/navigation/referrer.h"
#import "ui/base/l10n/l10n_util_mac.h"

@interface DriveBrowserCoordinator () <DriveBrowserMediatorDelegate,
                                       DriveBrowserTableViewControllerDelegate>
@end

@implementation DriveBrowserCoordinator {
  /// The mediator for business logic.
  DriveBrowserMediator* _mediator;

  /// The table view controller for displaying files.
  DriveBrowserTableViewController* _tableViewController;

  /// The navigation controller for modal presentation.
  UINavigationController* _navigationController;

  /// The file preview coordinator.
  DownloadFilePreviewCoordinator* _filePreviewCoordinator;

  /// The share activity controller.
  UIActivityViewController* _shareActivityController;

  /// Whether the coordinator has started.
  BOOL _started;
}

#pragma mark - ChromeCoordinator

- (void)start {
  if (_started) {
    return;
  }
  [super start];
  _started = YES;

  // Get the drive browser service.
  ProfileIOS* profile = self.browser->GetProfile();
  DriveBrowserService* service =
      DriveBrowserServiceFactory::GetForProfile(profile);

  // Create the mediator.
  _mediator = [[DriveBrowserMediator alloc] initWithService:service];
  _mediator.delegate = self;

  // Create the table view controller.
  _tableViewController = [[DriveBrowserTableViewController alloc]
      initWithStyle:UITableViewStyleInsetGrouped];
  _tableViewController.mutator = _mediator;
  _tableViewController.delegate = self;
  _mediator.consumer = _tableViewController;

  // Create the navigation controller.
  _navigationController = [[UINavigationController alloc]
      initWithRootViewController:_tableViewController];
  _navigationController.presentationController.delegate = _tableViewController;

  // Connect the mediator to start fetching files.
  [_mediator connect];

  // Present the modal.
  [self.baseViewController presentViewController:_navigationController
                                        animated:YES
                                      completion:nil];
}

- (void)stop {
  if (!_started) {
    return;
  }
  [super stop];
  _started = NO;

  // Dismiss the navigation controller if presented.
  if (_navigationController.presentingViewController) {
    [_navigationController.presentingViewController
        dismissViewControllerAnimated:YES
                           completion:nil];
  }

  // Stop file preview coordinator.
  if (_filePreviewCoordinator) {
    [_filePreviewCoordinator stop];
    _filePreviewCoordinator = nil;
  }

  // Disconnect the mediator.
  [_mediator disconnect];
  _mediator = nil;

  // Clean up.
  _tableViewController = nil;
  _navigationController = nil;
  _shareActivityController = nil;
}

#pragma mark - DriveBrowserMediatorDelegate

- (void)presentFilePreviewWithPath:(const base::FilePath&)filePath
                          mimeType:(NSString*)mimeType {
  // Check if this is a PDF that should open in a new tab.
  if ([mimeType isEqualToString:@"application/pdf"]) {
    [self openPDFInNewTab:filePath];
    return;
  }

  // Use QuickLook for other file types.
  if (!_filePreviewCoordinator) {
    _filePreviewCoordinator = [[DownloadFilePreviewCoordinator alloc]
        initWithBaseViewController:_tableViewController
                           browser:self.browser];
    [_filePreviewCoordinator start];
  }

  NSURL* fileURL =
      [NSURL fileURLWithPath:base::SysUTF8ToNSString(filePath.value())];
  [_filePreviewCoordinator presentFilePreviewWithURL:fileURL];
}

- (void)presentShareSheetWithPath:(const base::FilePath&)filePath
                       sourceView:(UIView*)sourceView {
  NSURL* fileURL =
      [NSURL fileURLWithPath:base::SysUTF8ToNSString(filePath.value())];
  if (!fileURL) {
    return;
  }

  _shareActivityController =
      [[UIActivityViewController alloc] initWithActivityItems:@[ fileURL ]
                                        applicationActivities:nil];

  // Configure popover presentation for iPad.
  _shareActivityController.popoverPresentationController.sourceView =
      sourceView;
  _shareActivityController.popoverPresentationController.sourceRect =
      sourceView.bounds;

  [_tableViewController presentViewController:_shareActivityController
                                     animated:YES
                                   completion:nil];
}

- (void)openInFilesApp:(const base::FilePath&)filePath {
  NSString* pathString = base::SysUTF8ToNSString(filePath.value());
  NSString* filesURLString =
      [NSString stringWithFormat:@"shareddocuments://%@", pathString];
  NSURL* filesURL = [NSURL URLWithString:filesURLString];

  if (filesURL) {
    [[UIApplication sharedApplication] openURL:filesURL
                                       options:@{}
                             completionHandler:nil];
  }
}

- (void)didDeleteItemAtIndex:(NSUInteger)index {
  [_tableViewController removeItemAtIndex:index];
}

- (void)didFailToDeleteItem:(DriveBrowserItem*)item {
  // Show an alert for delete failure.
  UIAlertController* alert = [UIAlertController
      alertControllerWithTitle:l10n_util::GetNSString(
                                   IDS_IOS_DOWNLOAD_MANAGER_DOWNLOAD_FAILED)
                       message:nil
                preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction* okAction =
      [UIAlertAction actionWithTitle:l10n_util::GetNSString(IDS_OK)
                               style:UIAlertActionStyleDefault
                             handler:nil];
  [alert addAction:okAction];

  [_tableViewController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - DriveBrowserTableViewControllerDelegate

- (void)driveBrowserTableViewControllerDidDismiss {
  [self stop];
}

#pragma mark - Private Methods

- (void)openPDFInNewTab:(const base::FilePath&)filePath {
  NSURL* fileURL =
      [NSURL fileURLWithPath:base::SysUTF8ToNSString(filePath.value())];
  GURL filePathURL = GURL(base::SysNSStringToUTF8([fileURL absoluteString]));

  OpenNewTabCommand* command = [[OpenNewTabCommand alloc]
       initWithURL:filePathURL
        virtualURL:GURL()
          referrer:web::Referrer()
       inIncognito:self.browser->GetProfile()->IsOffTheRecord()
      inBackground:NO
          appendTo:OpenPosition::kCurrentTab];

  id<ApplicationCommands> applicationCommands = HandlerForProtocol(
      self.browser->GetCommandDispatcher(), ApplicationCommands);
  [applicationCommands openURLInNewTab:command];

  // Dismiss the drive browser after opening the PDF.
  [self stop];
}

@end
