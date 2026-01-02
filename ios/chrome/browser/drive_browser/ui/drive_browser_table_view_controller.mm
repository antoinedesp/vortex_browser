// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/drive_browser/ui/drive_browser_table_view_controller.h"

#import "ios/chrome/browser/drive_browser/model/active_download_item.h"
#import "ios/chrome/browser/drive_browser/model/drive_browser_item.h"
#import "ios/chrome/browser/drive_browser/ui/active_download_cell.h"
#import "ios/chrome/browser/drive_browser/ui/drive_browser_constants.h"
#import "ios/chrome/browser/drive_browser/ui/drive_browser_empty_view.h"
#import "ios/chrome/browser/drive_browser/ui/drive_browser_mutator.h"
#import "ios/chrome/common/ui/colors/semantic_color_names.h"
#import "ios/chrome/grit/ios_strings.h"
#import "ui/base/l10n/l10n_util_mac.h"

namespace {

// Section identifiers.
typedef NS_ENUM(NSInteger, DriveBrowserSection) {
  DriveBrowserSectionActiveDownloads = 0,
  DriveBrowserSectionCompletedFiles = 1,
  DriveBrowserSectionCount = 2,
};

}  // namespace

@interface DriveBrowserTableViewController ()
@end

@implementation DriveBrowserTableViewController {
  /// The completed file items to display.
  NSArray<DriveBrowserItem*>* _items;

  /// The active downloads to display.
  NSArray<ActiveDownloadItem*>* _activeDownloads;

  /// The empty state view.
  DriveBrowserEmptyView* _emptyView;

  /// Loading indicator.
  UIActivityIndicatorView* _loadingIndicator;

  /// Refresh control for pull-to-refresh.
  UIRefreshControl* _refreshControl;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (self) {
    _items = @[];
    _activeDownloads = @[];
  }
  return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.accessibilityIdentifier = kDriveBrowserViewControllerAccessibilityId;
  self.tableView.accessibilityIdentifier = kDriveBrowserTableViewAccessibilityId;

  // Configure navigation bar.
  self.title = l10n_util::GetNSString(IDS_IOS_TOOLS_MENU_DOWNLOADS);
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                           target:self
                           action:@selector(doneButtonTapped)];
  self.navigationItem.rightBarButtonItem.accessibilityIdentifier =
      kDriveBrowserCloseButtonAccessibilityId;

  // Configure table view.
  self.tableView.rowHeight = UITableViewAutomaticDimension;
  self.tableView.estimatedRowHeight = kDriveBrowserItemCellHeight;
  self.tableView.separatorInset = UIEdgeInsetsMake(0, 64, 0, 0);
  [self.tableView registerClass:[UITableViewCell class]
         forCellReuseIdentifier:kDriveBrowserItemCellReuseId];
  [self.tableView registerClass:[ActiveDownloadCell class]
         forCellReuseIdentifier:kActiveDownloadCellReuseIdentifier];

  // Setup empty view.
  _emptyView = [[DriveBrowserEmptyView alloc] initWithFrame:CGRectZero];
  _emptyView.hidden = YES;

  // Setup loading indicator.
  _loadingIndicator = [[UIActivityIndicatorView alloc]
      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
  _loadingIndicator.hidesWhenStopped = YES;

  // Setup refresh control.
  _refreshControl = [[UIRefreshControl alloc] init];
  [_refreshControl addTarget:self
                      action:@selector(handleRefresh)
            forControlEvents:UIControlEventValueChanged];
  self.refreshControl = _refreshControl;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.presentationController.delegate = self;
}

#pragma mark - DriveBrowserConsumer

- (void)setItems:(NSArray<DriveBrowserItem*>*)items {
  _items = [items copy];
  [self.tableView reloadData];
  [_refreshControl endRefreshing];
  [self updateEmptyState];
}

- (void)setLoadingState:(BOOL)loading {
  if (loading) {
    [_loadingIndicator startAnimating];
    self.tableView.backgroundView = _loadingIndicator;
  } else {
    [_loadingIndicator stopAnimating];
    [self updateEmptyState];
  }
}

- (void)setEmptyState:(BOOL)empty {
  _emptyView.hidden = !empty;
  if (empty) {
    self.tableView.backgroundView = _emptyView;
  } else {
    self.tableView.backgroundView = nil;
  }
}

- (void)removeItemAtIndex:(NSUInteger)index {
  if (index >= _items.count) {
    return;
  }

  NSMutableArray* mutableItems = [_items mutableCopy];
  [mutableItems removeObjectAtIndex:index];
  _items = mutableItems;

  NSIndexPath* indexPath =
      [NSIndexPath indexPathForRow:index
                         inSection:DriveBrowserSectionCompletedFiles];
  [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                        withRowAnimation:UITableViewRowAnimationAutomatic];
  [self updateEmptyState];
}

#pragma mark - DriveBrowserConsumer (Optional - Active Downloads)

- (void)setActiveDownloads:(NSArray<ActiveDownloadItem*>*)downloads {
  _activeDownloads = [downloads copy];
  [self.tableView reloadSections:[NSIndexSet
                                     indexSetWithIndex:DriveBrowserSectionActiveDownloads]
                withRowAnimation:UITableViewRowAnimationAutomatic];
  [self updateEmptyState];
}

- (void)updateDownloadProgress:(NSString*)identifier
                      progress:(float)progress
                 bytesReceived:(int64_t)bytesReceived
                    totalBytes:(int64_t)totalBytes {
  // Find the download item and update the cell.
  for (NSUInteger i = 0; i < _activeDownloads.count; i++) {
    ActiveDownloadItem* item = _activeDownloads[i];
    if ([item.identifier isEqualToString:identifier]) {
      NSIndexPath* indexPath =
          [NSIndexPath indexPathForRow:i
                             inSection:DriveBrowserSectionActiveDownloads];
      ActiveDownloadCell* cell =
          (ActiveDownloadCell*)[self.tableView cellForRowAtIndexPath:indexPath];
      if (cell) {
        [cell updateProgress:progress];
        [cell updateProgressText:[item progressString]];
      }
      break;
    }
  }
}

- (void)updateDownloadState:(NSString*)identifier state:(NSInteger)state {
  // Find the download item and update the cell.
  for (NSUInteger i = 0; i < _activeDownloads.count; i++) {
    ActiveDownloadItem* item = _activeDownloads[i];
    if ([item.identifier isEqualToString:identifier]) {
      NSIndexPath* indexPath =
          [NSIndexPath indexPathForRow:i
                             inSection:DriveBrowserSectionActiveDownloads];
      ActiveDownloadCell* cell =
          (ActiveDownloadCell*)[self.tableView cellForRowAtIndexPath:indexPath];
      if (cell) {
        [cell configureWithItem:item];
      }
      break;
    }
  }
}

- (void)removeActiveDownload:(NSString*)identifier {
  // Find and remove the download.
  NSMutableArray* mutableDownloads = [_activeDownloads mutableCopy];
  for (NSUInteger i = 0; i < mutableDownloads.count; i++) {
    ActiveDownloadItem* item = mutableDownloads[i];
    if ([item.identifier isEqualToString:identifier]) {
      [mutableDownloads removeObjectAtIndex:i];
      _activeDownloads = mutableDownloads;

      NSIndexPath* indexPath =
          [NSIndexPath indexPathForRow:i
                             inSection:DriveBrowserSectionActiveDownloads];
      [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                            withRowAnimation:UITableViewRowAnimationAutomatic];
      break;
    }
  }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return DriveBrowserSectionCount;
}

- (NSInteger)tableView:(UITableView*)tableView
    numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case DriveBrowserSectionActiveDownloads:
      return _activeDownloads.count;
    case DriveBrowserSectionCompletedFiles:
      return _items.count;
    default:
      return 0;
  }
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  if (indexPath.section == DriveBrowserSectionActiveDownloads) {
    ActiveDownloadCell* cell = [tableView
        dequeueReusableCellWithIdentifier:kActiveDownloadCellReuseIdentifier
                             forIndexPath:indexPath];

    ActiveDownloadItem* item = _activeDownloads[indexPath.row];
    [cell configureWithItem:item];

    __weak __typeof(self) weakSelf = self;
    cell.cancelHandler = ^{
      [weakSelf.mutator userDidCancelDownload:item];
    };

    return cell;
  }

  // Completed files section.
  UITableViewCell* cell =
      [tableView dequeueReusableCellWithIdentifier:kDriveBrowserItemCellReuseId
                                      forIndexPath:indexPath];

  DriveBrowserItem* item = _items[indexPath.row];
  [self configureCell:cell withItem:item atIndexPath:indexPath];

  return cell;
}

- (NSString*)tableView:(UITableView*)tableView
    titleForHeaderInSection:(NSInteger)section {
  switch (section) {
    case DriveBrowserSectionActiveDownloads:
      return _activeDownloads.count > 0 ? @"Downloading" : nil;
    case DriveBrowserSectionCompletedFiles:
      return (_activeDownloads.count > 0 && _items.count > 0) ? @"Downloaded"
                                                              : nil;
    default:
      return nil;
  }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView
    didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  // Only allow selection of completed files.
  if (indexPath.section != DriveBrowserSectionCompletedFiles) {
    return;
  }

  DriveBrowserItem* item = _items[indexPath.row];
  [self.mutator userDidSelectItem:item];
}

- (UISwipeActionsConfiguration*)tableView:(UITableView*)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath*)indexPath {
  // No swipe actions for active downloads.
  if (indexPath.section != DriveBrowserSectionCompletedFiles) {
    return nil;
  }

  DriveBrowserItem* item = _items[indexPath.row];

  // Delete action.
  UIContextualAction* deleteAction = [UIContextualAction
      contextualActionWithStyle:UIContextualActionStyleDestructive
                          title:l10n_util::GetNSString(
                                    IDS_IOS_DELETE_ACTION_TITLE)
                        handler:^(UIContextualAction* action,
                                  UIView* sourceView,
                                  void (^completionHandler)(BOOL)) {
                          [self.mutator userDidDeleteItem:item];
                          completionHandler(YES);
                        }];
  deleteAction.image = [UIImage systemImageNamed:@"trash"];

  // Share action.
  UIContextualAction* shareAction = [UIContextualAction
      contextualActionWithStyle:UIContextualActionStyleNormal
                          title:l10n_util::GetNSString(
                                    IDS_IOS_SHARE_BUTTON_LABEL)
                        handler:^(UIContextualAction* action,
                                  UIView* sourceView,
                                  void (^completionHandler)(BOOL)) {
                          UITableViewCell* cell =
                              [tableView cellForRowAtIndexPath:indexPath];
                          [self.mutator userDidShareItem:item
                                              sourceView:cell];
                          completionHandler(YES);
                        }];
  shareAction.image = [UIImage systemImageNamed:@"square.and.arrow.up"];
  shareAction.backgroundColor = [UIColor systemBlueColor];

  return [UISwipeActionsConfiguration
      configurationWithActions:@[ deleteAction, shareAction ]];
}

- (UIContextMenuConfiguration*)tableView:(UITableView*)tableView
    contextMenuConfigurationForRowAtIndexPath:(NSIndexPath*)indexPath
                                        point:(CGPoint)point {
  // No context menu for active downloads.
  if (indexPath.section != DriveBrowserSectionCompletedFiles) {
    return nil;
  }

  DriveBrowserItem* item = _items[indexPath.row];

  return [UIContextMenuConfiguration
      configurationWithIdentifier:nil
                  previewProvider:nil
                   actionProvider:^UIMenu*(
                       NSArray<UIMenuElement*>* suggestedActions) {
                     return [self contextMenuForItem:item atIndexPath:indexPath];
                   }];
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (void)presentationControllerDidDismiss:
    (UIPresentationController*)presentationController {
  [self.delegate driveBrowserTableViewControllerDidDismiss];
}

#pragma mark - Private Methods

- (void)configureCell:(UITableViewCell*)cell
             withItem:(DriveBrowserItem*)item
          atIndexPath:(NSIndexPath*)indexPath {
  UIListContentConfiguration* config =
      [UIListContentConfiguration subtitleCellConfiguration];

  config.text = item.fileName;
  config.secondaryText = item.detailText;
  config.image = item.fileTypeIcon;
  config.imageProperties.tintColor = item.fileTypeIconColor;
  config.imageProperties.maximumSize =
      CGSizeMake(kDriveBrowserItemIconSize, kDriveBrowserItemIconSize);

  cell.contentConfiguration = config;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.accessibilityIdentifier = [NSString
      stringWithFormat:@"%@%ld", kDriveBrowserItemCellAccessibilityIdPrefix,
                       (long)indexPath.row];
}

- (UIMenu*)contextMenuForItem:(DriveBrowserItem*)item
                  atIndexPath:(NSIndexPath*)indexPath {
  NSMutableArray<UIAction*>* actions = [[NSMutableArray alloc] init];

  // Open/Preview action.
  UIAction* openAction = [UIAction
      actionWithTitle:l10n_util::GetNSString(IDS_IOS_DOWNLOAD_MANAGER_OPEN)
                image:[UIImage systemImageNamed:@"eye"]
           identifier:nil
              handler:^(__kindof UIAction* action) {
                [self.mutator userDidSelectItem:item];
              }];
  [actions addObject:openAction];

  // Share action.
  UIAction* shareAction = [UIAction
      actionWithTitle:l10n_util::GetNSString(IDS_IOS_SHARE_BUTTON_LABEL)
                image:[UIImage systemImageNamed:@"square.and.arrow.up"]
           identifier:nil
              handler:^(__kindof UIAction* action) {
                UITableViewCell* cell =
                    [self.tableView cellForRowAtIndexPath:indexPath];
                [self.mutator userDidShareItem:item sourceView:cell];
              }];
  [actions addObject:shareAction];

  // Open in Files action.
  UIAction* openInFilesAction = [UIAction
      actionWithTitle:l10n_util::GetNSString(
                          IDS_IOS_OPEN_IN_FILES_APP_ACTION_TITLE)
                image:[UIImage systemImageNamed:@"folder"]
           identifier:nil
              handler:^(__kindof UIAction* action) {
                [self.mutator userDidOpenInFilesApp:item];
              }];
  [actions addObject:openInFilesAction];

  // Delete action.
  UIAction* deleteAction = [UIAction
      actionWithTitle:l10n_util::GetNSString(IDS_IOS_DELETE_ACTION_TITLE)
                image:[UIImage systemImageNamed:@"trash"]
           identifier:nil
              handler:^(__kindof UIAction* action) {
                [self.mutator userDidDeleteItem:item];
              }];
  deleteAction.attributes = UIMenuElementAttributesDestructive;
  [actions addObject:deleteAction];

  return [UIMenu menuWithTitle:@"" children:actions];
}

- (void)doneButtonTapped {
  [self.presentingViewController dismissViewControllerAnimated:YES
                                                    completion:nil];
  [self.delegate driveBrowserTableViewControllerDidDismiss];
}

- (void)handleRefresh {
  [self.mutator userDidRefresh];
}

- (void)updateEmptyState {
  BOOL isEmpty = (_items.count == 0 && _activeDownloads.count == 0);
  [self setEmptyState:isEmpty];
}

@end
