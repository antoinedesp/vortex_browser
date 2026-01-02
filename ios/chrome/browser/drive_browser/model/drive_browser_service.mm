// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/drive_browser/model/drive_browser_service.h"

#import <Foundation/Foundation.h>

#import "base/files/file_enumerator.h"
#import "base/files/file_util.h"
#import "base/functional/bind.h"
#import "base/strings/sys_string_conversions.h"
#import "base/task/thread_pool.h"
#import "ios/chrome/browser/download/model/download_directory_util.h"
#import "ios/chrome/browser/drive_browser/model/drive_browser_item.h"

namespace {

// Returns the MIME type for a file based on its extension.
NSString* MimeTypeForFilePath(const base::FilePath& path) {
  std::string extension = path.Extension();
  if (extension.empty()) {
    return @"application/octet-stream";
  }

  // Remove the leading dot.
  if (extension[0] == '.') {
    extension = extension.substr(1);
  }

  // Convert to lowercase for comparison.
  std::transform(extension.begin(), extension.end(), extension.begin(),
                 ::tolower);

  // Video types
  if (extension == "mp4" || extension == "m4v") {
    return @"video/mp4";
  }
  if (extension == "mov") {
    return @"video/quicktime";
  }
  if (extension == "avi") {
    return @"video/x-msvideo";
  }
  if (extension == "mkv") {
    return @"video/x-matroska";
  }
  if (extension == "webm") {
    return @"video/webm";
  }

  // Image types
  if (extension == "jpg" || extension == "jpeg") {
    return @"image/jpeg";
  }
  if (extension == "png") {
    return @"image/png";
  }
  if (extension == "gif") {
    return @"image/gif";
  }
  if (extension == "webp") {
    return @"image/webp";
  }
  if (extension == "heic" || extension == "heif") {
    return @"image/heic";
  }
  if (extension == "svg") {
    return @"image/svg+xml";
  }

  // Document types
  if (extension == "pdf") {
    return @"application/pdf";
  }
  if (extension == "doc") {
    return @"application/msword";
  }
  if (extension == "docx") {
    return @"application/vnd.openxmlformats-officedocument.wordprocessingml.document";
  }
  if (extension == "txt") {
    return @"text/plain";
  }
  if (extension == "rtf") {
    return @"application/rtf";
  }
  if (extension == "html" || extension == "htm") {
    return @"text/html";
  }

  // Archive types
  if (extension == "zip") {
    return @"application/zip";
  }
  if (extension == "rar") {
    return @"application/x-rar-compressed";
  }
  if (extension == "7z") {
    return @"application/x-7z-compressed";
  }
  if (extension == "gz" || extension == "gzip") {
    return @"application/gzip";
  }
  if (extension == "tar") {
    return @"application/x-tar";
  }

  return @"application/octet-stream";
}

// Scans the downloads directory and returns a list of DriveBrowserItems.
NSArray<DriveBrowserItem*>* ScanDirectoryForFiles() {
  base::FilePath downloads_dir;
  GetDownloadsDirectory(&downloads_dir);

  if (!base::DirectoryExists(downloads_dir)) {
    return @[];
  }

  NSMutableArray<DriveBrowserItem*>* items = [[NSMutableArray alloc] init];

  base::FileEnumerator enumerator(downloads_dir, /*recursive=*/false,
                                  base::FileEnumerator::FILES);

  for (base::FilePath path = enumerator.Next(); !path.empty();
       path = enumerator.Next()) {
    base::FileEnumerator::FileInfo info = enumerator.GetInfo();

    // Skip hidden files.
    if (path.BaseName().value()[0] == '.') {
      continue;
    }

    int64_t file_size = info.GetSize();
    base::Time creation_time = info.GetLastModifiedTime();
    NSString* mime_type = MimeTypeForFilePath(path);

    DriveBrowserItem* item =
        [[DriveBrowserItem alloc] initWithFilePath:path
                                          fileSize:file_size
                                          mimeType:mime_type
                                       createdTime:creation_time];
    [items addObject:item];
  }

  // Sort by creation time (newest first).
  [items sortUsingComparator:^NSComparisonResult(DriveBrowserItem* a,
                                                  DriveBrowserItem* b) {
    if (a.createdTime > b.createdTime) {
      return NSOrderedAscending;
    }
    if (a.createdTime < b.createdTime) {
      return NSOrderedDescending;
    }
    return NSOrderedSame;
  }];

  return items;
}

// Deletes a file at the specified path. Returns true on success.
bool DeleteFileAtPath(const base::FilePath& path) {
  return base::DeleteFile(path);
}

}  // namespace

DriveBrowserService::DriveBrowserService() = default;

DriveBrowserService::~DriveBrowserService() = default;

void DriveBrowserService::GetAllFiles(DriveBrowserItemsCallback callback) {
  ScanDownloadsDirectory(std::move(callback));
}

void DriveBrowserService::GetFilesByType(int file_type,
                                          DriveBrowserItemsCallback callback) {
  base::ThreadPool::PostTaskAndReplyWithResult(
      FROM_HERE,
      {base::MayBlock(), base::TaskShutdownBehavior::SKIP_ON_SHUTDOWN},
      base::BindOnce(&ScanDirectoryForFiles),
      base::BindOnce(
          [](int file_type, DriveBrowserItemsCallback callback,
             NSArray<DriveBrowserItem*>* all_items) {
            NSMutableArray<DriveBrowserItem*>* filtered_items =
                [[NSMutableArray alloc] init];
            for (DriveBrowserItem* item in all_items) {
              if (item.fileType == file_type) {
                [filtered_items addObject:item];
              }
            }
            std::move(callback).Run(filtered_items);
          },
          file_type, std::move(callback)));
}

void DriveBrowserService::DeleteFile(const base::FilePath& file_path,
                                      DriveBrowserDeleteCallback callback) {
  base::ThreadPool::PostTaskAndReplyWithResult(
      FROM_HERE,
      {base::MayBlock(), base::TaskShutdownBehavior::SKIP_ON_SHUTDOWN},
      base::BindOnce(&DeleteFileAtPath, file_path), std::move(callback));
}

void DriveBrowserService::RefreshFileList() {
  // This method can be used to trigger a refresh if needed.
  // Currently, GetAllFiles always rescans the directory.
}

base::WeakPtr<DriveBrowserService> DriveBrowserService::GetWeakPtr() {
  return weak_ptr_factory_.GetWeakPtr();
}

void DriveBrowserService::Shutdown() {
  weak_ptr_factory_.InvalidateWeakPtrs();
}

void DriveBrowserService::ScanDownloadsDirectory(
    DriveBrowserItemsCallback callback) {
  base::ThreadPool::PostTaskAndReplyWithResult(
      FROM_HERE,
      {base::MayBlock(), base::TaskShutdownBehavior::SKIP_ON_SHUTDOWN},
      base::BindOnce(&ScanDirectoryForFiles), std::move(callback));
}
