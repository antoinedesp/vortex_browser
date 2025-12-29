// Copyright 2023 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftUI

struct OverflowMenuRowIcon: View {
  var symbolName: String
  var systemSymbol: Bool
  var monochromeSymbol: Bool

  // Smaller icon size for compact design
  static let symbolImageFrameLength: CGFloat = 24
  static let symbolSize: CGFloat = 16

  var body: some View {
    symbol
      .font(Font.system(size: Self.symbolSize, weight: .medium))
      .imageScale(.medium)
      .frame(
        width: Self.symbolImageFrameLength,
        height: Self.symbolImageFrameLength, alignment: .center
      )
      // Use semantic color: dark/gray in light mode, light/white in dark mode
      .foregroundColor(Color(.secondaryLabel))
      // Without explicitly removing the image from accessibility,
      // VoiceOver will occasionally read out icons it thinks it can
      // recognize.
      .accessibilityHidden(true)
  }

  var symbol: Image {
    let symbol =
      systemSymbol ? Image(systemName: symbolName) : Image(symbolName)
    if monochromeSymbol {
      return symbol.symbolRenderingMode(.monochrome)
    }
    return symbol
  }
}
