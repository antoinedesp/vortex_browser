// Copyright 2024 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_COMMON_UI_INSTRUCTION_VIEW_VORTEX_INSTRUCTION_VIEW_H_
#define IOS_CHROME_COMMON_UI_INSTRUCTION_VIEW_VORTEX_INSTRUCTION_VIEW_H_

#import <UIKit/UIKit.h>

// A view that displays a list of instructions with checkmark icons instead of numbers.
// This is specifically designed for the Vortex VPN onboarding flow.
@interface VortexInstructionView : UIView

// Initializes the view with a list of instruction strings.
// Each instruction will be displayed with a green checkmark icon.
- (instancetype)initWithList:(NSArray<NSString*>*)instructionList NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder*)coder NS_UNAVAILABLE;

@end

#endif  // IOS_CHROME_COMMON_UI_INSTRUCTION_VIEW_VORTEX_INSTRUCTION_VIEW_H_