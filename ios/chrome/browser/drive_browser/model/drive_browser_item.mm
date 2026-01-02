// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/drive_browser/model/drive_browser_item.h"

#import "base/strings/sys_string_conversions.h"
#import "ios/chrome/browser/shared/ui/symbols/symbols.h"

namespace {

// SF Symbol names for file types.
NSString* const kVideoSymbol = @"video.fill";
NSString* const kImageSymbol = @"photo.fill";
NSString* const kDocumentSymbol = @"doc.fill";
NSString* const kTextDocumentSymbol = @"doc.text.fill";
NSString* const kArchiveSymbol = @"archivebox.fill";
NSString* const kGenericFileSymbol = @"doc.fill";

// Returns the file type based on MIME type.
DriveBrowserFileType FileTypeFromMimeType(NSString* mimeType) {
  if (!mimeType) {
    return DriveBrowserFileTypeOther;
  }

  NSString* lowerMimeType = [mimeType lowercaseString];

  if ([lowerMimeType hasPrefix:@"video/"]) {
    return DriveBrowserFileTypeVideo;
  }
  if ([lowerMimeType hasPrefix:@"image/"]) {
    return DriveBrowserFileTypeImage;
  }
  if ([lowerMimeType isEqualToString:@"application/pdf"] ||
      [lowerMimeType hasPrefix:@"text/"] ||
      [lowerMimeType isEqualToString:@"application/msword"] ||
      [lowerMimeType hasPrefix:@"application/vnd.openxmlformats"]) {
    return DriveBrowserFileTypeDocument;
  }
  if ([lowerMimeType isEqualToString:@"application/zip"] ||
      [lowerMimeType isEqualToString:@"application/x-rar-compressed"] ||
      [lowerMimeType isEqualToString:@"application/gzip"] ||
      [lowerMimeType isEqualToString:@"application/x-7z-compressed"]) {
    return DriveBrowserFileTypeArchive;
  }

  return DriveBrowserFileTypeOther;
}

// Returns the SF Symbol name for a file type.
NSString* SymbolNameForFileType(DriveBrowserFileType fileType) {
  switch (fileType) {
    case DriveBrowserFileTypeVideo:
      return kVideoSymbol;
    case DriveBrowserFileTypeImage:
      return kImageSymbol;
    case DriveBrowserFileTypeDocument:
      return kTextDocumentSymbol;
    case DriveBrowserFileTypeArchive:
      return kArchiveSymbol;
    case DriveBrowserFileTypeOther:
      return kGenericFileSymbol;
  }
}

// Returns the icon color for a file type.
UIColor* ColorForFileType(DriveBrowserFileType fileType) {
  switch (fileType) {
    case DriveBrowserFileTypeVideo:
      return [UIColor systemPurpleColor];
    case DriveBrowserFileTypeImage:
      return [UIColor systemBlueColor];
    case DriveBrowserFileTypeDocument:
      return [UIColor systemRedColor];
    case DriveBrowserFileTypeArchive:
      return [UIColor systemBrownColor];
    case DriveBrowserFileTypeOther:
      return [UIColor systemGrayColor];
  }
}

// Formats file size to human-readable string.
NSString* FormattedFileSizeFromBytes(int64_t bytes) {
  NSByteCountFormatter* formatter = [[NSByteCountFormatter alloc] init];
  formatter.countStyle = NSByteCountFormatterCountStyleFile;
  return [formatter stringFromByteCount:bytes];
}

// Formats date to human-readable string.
NSString* FormattedDateFromTime(base::Time time) {
  if (time.is_null()) {
    return @"";
  }

  NSDate* date = [NSDate dateWithTimeIntervalSince1970:time.InSecondsFSinceUnixEpoch()];
  NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
  formatter.dateStyle = NSDateFormatterMediumStyle;
  formatter.timeStyle = NSDateFormatterShortStyle;
  return [formatter stringFromDate:date];
}

}  // namespace

@implementation DriveBrowserItem {
  base::FilePath _filePath;
  int64_t _fileSize;
  NSString* _mimeType;
  base::Time _createdTime;
  DriveBrowserFileType _fileType;
}

- (instancetype)initWithFilePath:(const base::FilePath&)filePath
                        fileSize:(int64_t)fileSize
                        mimeType:(NSString*)mimeType
                     createdTime:(base::Time)createdTime {
  self = [super init];
  if (self) {
    _filePath = filePath;
    _fileSize = fileSize;
    _mimeType = [mimeType copy];
    _createdTime = createdTime;
    _fileType = FileTypeFromMimeType(mimeType);
  }
  return self;
}

#pragma mark - Properties

- (NSString*)fileName {
  return base::SysUTF8ToNSString(_filePath.BaseName().value());
}

- (base::FilePath)filePath {
  return _filePath;
}

- (DriveBrowserFileType)fileType {
  return _fileType;
}

- (int64_t)fileSize {
  return _fileSize;
}

- (NSString*)mimeType {
  return _mimeType;
}

- (base::Time)createdTime {
  return _createdTime;
}

- (UIImage*)fileTypeIcon {
  NSString* symbolName = SymbolNameForFileType(_fileType);
  UIImageConfiguration* config = [UIImageSymbolConfiguration
      configurationWithPointSize:24
                          weight:UIImageSymbolWeightRegular];
  return [UIImage systemImageNamed:symbolName withConfiguration:config];
}

- (UIColor*)fileTypeIconColor {
  return ColorForFileType(_fileType);
}

- (NSString*)formattedFileSize {
  return FormattedFileSizeFromBytes(_fileSize);
}

- (NSString*)formattedDate {
  return FormattedDateFromTime(_createdTime);
}

- (NSString*)detailText {
  NSString* sizeText = self.formattedFileSize;
  NSString* dateText = self.formattedDate;

  if (sizeText.length > 0 && dateText.length > 0) {
    return [NSString stringWithFormat:@"%@ - %@", sizeText, dateText];
  }
  if (sizeText.length > 0) {
    return sizeText;
  }
  return dateText;
}

- (DriveBrowserItemAction)availableActions {
  return DriveBrowserItemActionPreview | DriveBrowserItemActionShare |
         DriveBrowserItemActionOpenInFiles | DriveBrowserItemActionDelete;
}

#pragma mark - Public Methods

- (BOOL)isEqualToItem:(DriveBrowserItem*)item {
  if (!item) {
    return NO;
  }
  return _filePath == item->_filePath && _fileSize == item->_fileSize &&
         [_mimeType isEqualToString:item->_mimeType] &&
         _createdTime == item->_createdTime;
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[DriveBrowserItem class]]) {
    return NO;
  }
  return [self isEqualToItem:object];
}

- (NSUInteger)hash {
  return std::hash<std::string>{}(_filePath.value()) ^ std::hash<int64_t>{}(_fileSize);
}

@end
