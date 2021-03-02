//
// UIView+SAGesture.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2020/12/4.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+SAGesture.h"
#import "UIGestureRecognizer+SAAutoTrack.h"
#import "SAGestureViewIgnore.h"
#import "SAGestureViewProcessorHandler.h"
#import "SAViewElementInfoFactory.h"
#import "SAVisualizedUtils.h"

@implementation UIView (SAGesture)

- (BOOL)sensorsdata_isGestureVisualView {
    if (!self.userInteractionEnabled) {
        return NO;
    }
    if (![SAVisualizedUtils isVisibleForView:self]) {
        return NO;
    }
    if ([SAGestureViewIgnore ignoreWithView:self]) {
        return NO;
    }
    SAViewElementInfo *elementInfo = [SAViewElementInfoFactory elementInfoWithView:self];
    if (![[elementInfo elementType] isEqualToString:NSStringFromClass(self.class)]) {
        return YES;
    }
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        BOOL existSensorsTarget = gesture.sensorsdata_gestureTarget != nil;
        BOOL existCustomTarget = [SAGestureTargetActionPair filterValidPairsFrom:gesture.sensorsdata_targetActionPairs].count > 0;
        if (existSensorsTarget && existCustomTarget) {
            SAGestureViewProcessorHandler *handler = [[SAGestureViewProcessorHandler alloc] initWithGesture:gesture];
            if (handler.trackableView == gesture.view) {
                return YES;
            }
        }
    }
    return NO;
}

@end
