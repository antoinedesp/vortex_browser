// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_DRIVE_BROWSER_MODEL_DRIVE_BROWSER_SERVICE_H_
#define IOS_CHROME_BROWSER_DRIVE_BROWSER_MODEL_DRIVE_BROWSER_SERVICE_H_

#import <Foundation/Foundation.h>
#import <vector>

#import "base/files/file_path.h"
#import "base/functional/callback.h"
#import "base/memory/weak_ptr.h"
#import "components/keyed_service/core/keyed_service.h"

@class DriveBrowserItem;

/// Callback type for fetching drive browser items.
using DriveBrowserItemsCallback =
    base::OnceCallback<void(NSArray<DriveBrowserItem*>*)>;

/// Callback type for delete operations.
using DriveBrowserDeleteCallback = base::OnceCallback<void(bool success)>;

/// Service for managing files in the drive browser.
/// Provides methods to fetch, categorize, and delete files from the
/// downloads directory.
class DriveBrowserService : public KeyedService {
 public:
  DriveBrowserService();
  ~DriveBrowserService() override;

  DriveBrowserService(const DriveBrowserService&) = delete;
  DriveBrowserService& operator=(const DriveBrowserService&) = delete;

  /// Fetches all files from the downloads directory.
  /// Results are sorted by creation date (newest first).
  /// @param callback The callback to invoke with the fetched items.
  void GetAllFiles(DriveBrowserItemsCallback callback);

  /// Fetches files filtered by type.
  /// @param file_type The type of files to fetch (from DriveBrowserFileType).
  /// @param callback The callback to invoke with the fetched items.
  void GetFilesByType(int file_type, DriveBrowserItemsCallback callback);

  /// Deletes a file at the specified path.
  /// @param file_path The path of the file to delete.
  /// @param callback The callback to invoke with the result.
  void DeleteFile(const base::FilePath& file_path,
                  DriveBrowserDeleteCallback callback);

  /// Refreshes the file list by rescanning the downloads directory.
  void RefreshFileList();

  /// Returns a weak pointer to this service.
  base::WeakPtr<DriveBrowserService> GetWeakPtr();

  // KeyedService:
  void Shutdown() override;

 private:
  /// Scans the downloads directory for files.
  void ScanDownloadsDirectory(DriveBrowserItemsCallback callback);

  /// Weak pointer factory for this service.
  base::WeakPtrFactory<DriveBrowserService> weak_ptr_factory_{this};
};

#endif  // IOS_CHROME_BROWSER_DRIVE_BROWSER_MODEL_DRIVE_BROWSER_SERVICE_H_
