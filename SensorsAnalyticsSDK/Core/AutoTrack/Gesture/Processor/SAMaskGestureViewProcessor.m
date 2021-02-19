//
// SAMaskGestureViewProcessor.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/19.
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

#import "SAMaskGestureViewProcessor.h"
#import "SAAlertController.h"
#import "SAAutoTrackUtils.h"

#pragma mark - Mask
@implementation SAMaskGestureViewProcessor

#pragma mark - SAGestureViewProcessor
- (UIView *)trackableViewWithGesture:(UIGestureRecognizer *)gesture {
    NSArray <UIView *>*visualViews = [self searchVisualSubViewFromView:gesture.view];
    CGPoint currentPoint = [gesture locationInView:gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

#pragma mark - Util
- (NSArray <UIView *>*)searchVisualSubViewFromView:(UIView *)view {
    NSMutableArray *subViews = [NSMutableArray array];
    for (UIView *subView in view.subviews) {
        if ([[self subVisualViewType] isEqualToString:NSStringFromClass(subView.class)]) {
            [subViews addObject:subView];
        } else {
            NSArray *array = [self searchVisualSubViewFromView:subView];
            if (array.count > 0) {
                [subViews addObjectsFromArray:array];
            }
        }
    }
    return  [subViews copy];
}

#pragma mark - Subclasses to overwrite
- (NSString *)subVisualViewType {
    return @"";
}

@end

#pragma mark - Legacy Alert
@implementation SALegacyAlertGestureViewProcessor

#pragma mark - SAGestureViewProcessor
- (BOOL)trackableWithGesture:(UIGestureRecognizer *)gesture {
    if (![super trackableWithGesture:gesture]) {
        return NO;
    }
    // 屏蔽 SAAlertController 的点击事件
    UIViewController *viewController = [SAAutoTrackUtils findNextViewControllerByResponder:gesture.view];
    if ([viewController isKindOfClass:UIAlertController.class] && [viewController.nextResponder isKindOfClass:SAAlertController.class]) {
        return NO;
    }
    return YES;
}

#pragma mark - Overwrite
- (NSString *)subVisualViewType {
    return @"_UIAlertControllerCollectionViewCell";
}

@end

#pragma mark - New Alert
@implementation SANewAlertGestureViewProcessor

#pragma mark - SAGestureViewProcessor
- (BOOL)trackableWithGesture:(UIGestureRecognizer *)gesture {
    if (![super trackableWithGesture:gesture]) {
        return NO;
    }
    // 屏蔽 SAAlertController 的点击事件
    UIViewController *viewController = [SAAutoTrackUtils findNextViewControllerByResponder:gesture.view];
    if ([viewController isKindOfClass:UIAlertController.class] && [viewController.nextResponder isKindOfClass:SAAlertController.class]) {
        return NO;
    }
    return YES;
}

#pragma mark - Overwrite
- (NSString *)subVisualViewType {
    return @"_UIInterfaceActionCustomViewRepresentationView";
}

@end

#pragma mark - Menu
@implementation SAMenuGestureViewProcessor

#pragma mark - Overwrite
- (NSString *)subVisualViewType {
    return @"_UIContextMenuActionsListCell";
}

@end
