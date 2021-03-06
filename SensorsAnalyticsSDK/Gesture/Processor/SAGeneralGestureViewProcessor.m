//
// SAGeneralGestureViewProcessor.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/10.
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

#import "SAGeneralGestureViewProcessor.h"
#import "UIGestureRecognizer+SAAutoTrack.h"
#import "SAGestureViewIgnore.h"
#import "SAAlertController.h"
#import "SAAutoTrackUtils.h"

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

@interface SAGeneralGestureViewProcessor ()

@property (nonatomic, strong) UIGestureRecognizer *gesture;

@end

@implementation SAGeneralGestureViewProcessor

- (instancetype)initWithGesture:(UIGestureRecognizer *)gesture {
    if (self = [super init]) {
        self.gesture = gesture;
    }
    return self;
}

- (BOOL)isTrackable {
    if ([SAGestureViewIgnore ignoreWithView:self.gesture.view]) {
        return NO;
    }
    if ([SAGestureTargetActionPair filterValidPairsFrom:self.gesture.sensorsdata_targetActionPairs].count == 0) {
        return NO;
    }
    return YES;
}

- (UIView *)trackableView {
    return self.gesture.view;
}

@end

#pragma mark - 适配 iOS 10 以前的 Alert
@implementation SALegacyAlertGestureViewProcessor

- (BOOL)isTrackable {
    if (![super isTrackable]) {
        return NO;
    }
    // 屏蔽 SAAlertController 的点击事件
    UIViewController *viewController = [SAAutoTrackUtils findNextViewControllerByResponder:self.gesture.view];
    if ([viewController isKindOfClass:UIAlertController.class] && [viewController.nextResponder isKindOfClass:SAAlertController.class]) {
        return NO;
    }
    return YES;
}

- (UIView *)trackableView {
    NSArray <UIView *>*visualViews = sensorsdata_searchVisualSubView(@"_UIAlertControllerCollectionViewCell", self.gesture.view);
    CGPoint currentPoint = [self.gesture locationInView:self.gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:self.gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

@end

#pragma mark - 适配 iOS 10 及以后的 Alert
@implementation SANewAlertGestureViewProcessor

- (BOOL)isTrackable {
    if (![super isTrackable]) {
        return NO;
    }
    // 屏蔽 SAAlertController 的点击事件
    UIViewController *viewController = [SAAutoTrackUtils findNextViewControllerByResponder:self.gesture.view];
    if ([viewController isKindOfClass:UIAlertController.class] && [viewController.nextResponder isKindOfClass:SAAlertController.class]) {
        return NO;
    }
    return YES;
}

- (UIView *)trackableView {
    NSArray <UIView *>*visualViews = sensorsdata_searchVisualSubView(@"_UIInterfaceActionCustomViewRepresentationView", self.gesture.view);
    CGPoint currentPoint = [self.gesture locationInView:self.gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:self.gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

@end

#pragma mark - 适配 iOS 13 及以后的 UIMenu
@implementation SAMenuGestureViewProcessor

- (UIView *)trackableView {
    NSArray <UIView *>*visualViews = sensorsdata_searchVisualSubView(@"_UIContextMenuActionsListCell", self.gesture.view);
    CGPoint currentPoint = [self.gesture locationInView:self.gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:self.gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

@end

#pragma mark - TableViewCell.contentView 上仅存在系统手势时, 不支持可视化全埋点元素选中
@implementation SATableCellGestureViewProcessor

- (BOOL)isTrackable {
    if (![super isTrackable]) {
        return NO;
    }
    for (SAGestureTargetActionPair *pair in self.gesture.sensorsdata_targetActionPairs) {
        if (pair.isValid) {
            if (![NSStringFromSelector(pair.action) isEqualToString:@"_longPressGestureRecognized:"]) {
                return YES;
            }
        }
    }
    return NO;
}

@end

#pragma mark - CollectionViewCell.contentView 上仅存在系统手势时, 不支持可视化全埋点元素选中
@implementation SACollectionCellGestureViewProcessor

- (BOOL)isTrackable {
    if (![super isTrackable]) {
        return NO;
    }
    for (SAGestureTargetActionPair *pair in self.gesture.sensorsdata_targetActionPairs) {
        if (pair.isValid) {
            if (![NSStringFromSelector(pair.action) isEqualToString:@"_handleMenuGesture:"]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
