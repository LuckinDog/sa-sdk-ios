//
// SAAlertGestureViewProcessor.m
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

#import "SAAlertGestureViewProcessor.h"
#import "SAAlertController.h"
#import "SAAutoTrackUtils.h"
#import "UIGestureRecognizer+SAAutoTrack.h"
#import "SAGestureViewIgnore.h"

static NSArray <UIView *>* sensorsdata_searchVisualSubView(NSString *type, UIView *view) {
    NSMutableArray *subViews = [NSMutableArray array];
    for (UIView *subView in view.subviews) {
        if ([type isEqualToString:NSStringFromClass(subView.class)]) {
            [subViews addObject:subView];
        } else {
            NSArray *array = sensorsdata_searchVisualSubView(type, subView);
            if (array.count > 0) {
                [subViews addObjectsFromArray:array];
            }
        }
    }
    return  [subViews copy];
}

#pragma mark - Legacy Alert
@implementation SALegacyAlertGestureViewProcessor

- (BOOL)isTrackableWithGesture:(UIGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) {
        return NO;
    }
    if ([SAGestureViewIgnore ignoreWithView:gesture.view]) {
        return NO;
    }
    if ([SAGestureTargetActionPair filterValidPairsFrom:gesture.sensorsdata_targetActionPairs].count == 0) {
        return NO;
    }
    // 屏蔽 SAAlertController 的点击事件
    UIViewController *viewController = [SAAutoTrackUtils findNextViewControllerByResponder:gesture.view];
    if ([viewController isKindOfClass:UIAlertController.class] && [viewController.nextResponder isKindOfClass:SAAlertController.class]) {
        return NO;
    }
    return YES;
}

- (UIView *)trackableViewWithGesture:(UIGestureRecognizer *)gesture {
    NSArray <UIView *>*visualViews = sensorsdata_searchVisualSubView(@"_UIAlertControllerCollectionViewCell", gesture.view);
    CGPoint currentPoint = [gesture locationInView:gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

@end

#pragma mark - New Alert
@implementation SANewAlertGestureViewProcessor

- (BOOL)isTrackableWithGesture:(UIGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) {
        return NO;
    }
    if ([SAGestureViewIgnore ignoreWithView:gesture.view]) {
        return NO;
    }
    if ([SAGestureTargetActionPair filterValidPairsFrom:gesture.sensorsdata_targetActionPairs].count == 0) {
        return NO;
    }
    // 屏蔽 SAAlertController 的点击事件
    UIViewController *viewController = [SAAutoTrackUtils findNextViewControllerByResponder:gesture.view];
    if ([viewController isKindOfClass:UIAlertController.class] && [viewController.nextResponder isKindOfClass:SAAlertController.class]) {
        return NO;
    }
    return YES;
}

- (UIView *)trackableViewWithGesture:(UIGestureRecognizer *)gesture {
    NSArray <UIView *>*visualViews = sensorsdata_searchVisualSubView(@"_UIInterfaceActionCustomViewRepresentationView", gesture.view);
    CGPoint currentPoint = [gesture locationInView:gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

@end

#pragma mark - Menu
@implementation SAMenuGestureViewProcessor

- (BOOL)isTrackableWithGesture:(UIGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) {
        return NO;
    }
    if ([SAGestureViewIgnore ignoreWithView:gesture.view]) {
        return NO;
    }
    if ([SAGestureTargetActionPair filterValidPairsFrom:gesture.sensorsdata_targetActionPairs].count == 0) {
        return NO;
    }
    return YES;
}

- (UIView *)trackableViewWithGesture:(UIGestureRecognizer *)gesture {
    NSArray <UIView *>*visualViews = sensorsdata_searchVisualSubView(@"_UIContextMenuActionsListCell", gesture.view);
    CGPoint currentPoint = [gesture locationInView:gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

@end
