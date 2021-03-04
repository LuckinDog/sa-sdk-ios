//
// SAGestureManager.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/3/3.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAGestureManager.h"
#import "SASwizzle.h"
#import "UIGestureRecognizer+SAAutoTrack.h"
#import "SAGestureViewIgnore.h"
#import "SAGestureViewProcessorFactory.h"
#import "SAViewElementInfoFactory.h"
#import "SAVisualizedUtils.h"

@implementation SAGestureManager

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    
    if (enable) {
        [self enableAutoTrackGesture];
    }
}

- (void)enableAutoTrackGesture {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIGestureRecognizer sa_swizzleMethod:@selector(initWithTarget:action:)
                                   withMethod:@selector(sensorsdata_initWithTarget:action:)
                                        error:NULL];
        [UIGestureRecognizer sa_swizzleMethod:@selector(addTarget:action:)
                                   withMethod:@selector(sensorsdata_addTarget:action:)
                                        error:NULL];
        [UIGestureRecognizer sa_swizzleMethod:@selector(removeTarget:action:)
                                   withMethod:@selector(sensorsdata_removeTarget:action:)
                                        error:NULL];
    });
}

- (BOOL)isGestureVisualView:(id)obj {
    if (!self.enable) {
        return NO;
    }
    if (![obj isKindOfClass:UIView.class]) {
        return NO;
    }
    UIView *view = (UIView *)obj;
    if (!view.userInteractionEnabled) {
        return NO;
    }
    if (![SAVisualizedUtils isVisibleForView:view]) {
        return NO;
    }
    if ([SAGestureViewIgnore ignoreWithView:view]) {
        return NO;
    }
    SAViewElementInfo *elementInfo = [SAViewElementInfoFactory elementInfoWithView:view];
    if (![[elementInfo elementType] isEqualToString:NSStringFromClass(view.class)]) {
        return YES;
    }
    for (UIGestureRecognizer *gesture in view.gestureRecognizers) {
        BOOL existSensorsTarget = gesture.sensorsdata_gestureTarget != nil;
        BOOL existCustomTarget = [SAGestureTargetActionPair filterValidPairsFrom:gesture.sensorsdata_targetActionPairs].count > 0;
        if (existSensorsTarget && existCustomTarget) {
            SAGeneralGestureViewProcessor *processor = [SAGestureViewProcessorFactory processorWithGesture:gesture];
            if (processor.trackableView == gesture.view) {
                return YES;
            }
        }
    }
    return NO;
}

@end
