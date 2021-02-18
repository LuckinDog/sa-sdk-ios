//
// SAMenuGestureViewProcessor.m
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

#import "SAMenuGestureViewProcessor.h"
#import "SAAutoTrackUtils.h"

@implementation SAMenuGestureViewProcessor

- (BOOL)trackableWithGesture:(UIGestureRecognizer *)gesture {
    if (![super trackableWithGesture:gesture]) {
        return NO;
    }
    return YES;
}

- (UIView *)trackableViewWithGesture:(UIGestureRecognizer *)gesture {
    NSArray <UIView *>*visualViews = [self searchVisualSubViewWithType:@"_UIContextMenuActionsListCell" fromView:gesture.view];
    CGPoint currentPoint = [gesture locationInView:gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

- (NSArray <UIView *>*)searchVisualSubViewWithType:(NSString *)type fromView:(UIView *)view {
    NSMutableArray *subViews = [NSMutableArray array];
    for (UIView *subView in view.subviews) {
        if ([type isEqualToString:NSStringFromClass(subView.class)]) {
            [subViews addObject:subView];
        } else {
            NSArray *array = [self searchVisualSubViewWithType:type fromView:subView];
            if (array.count > 0) {
                [subViews addObjectsFromArray:array];
            }
        }
    }
    return  [subViews copy];
}

@end
