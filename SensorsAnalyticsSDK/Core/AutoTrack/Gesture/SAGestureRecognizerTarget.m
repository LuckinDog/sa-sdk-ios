//
// SAGestureRecognizerTarget.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2020/12/7.
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

#import "SAGestureRecognizerTarget.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAAutoTrackGestureConfig.h"
#import "SAConstants+Private.h"
#import "UIView+AutoTrack.h"
#import "SAAutoTrackUtils.h"
#import "UIView+SAGesture.h"

@implementation SAGestureRecognizerTarget

- (NSArray <UIView *>*)searchVisualSubViewFromView:(UIView *)view classes:(NSArray <NSString *>*)classes {
    if (!classes.count) return @[];
    
    NSMutableArray *subViews = [NSMutableArray array];
    for (UIView *subView in view.subviews) {
        if ([classes containsObject:NSStringFromClass(subView.class)]) {
            [subViews addObject:subView];
        } else {
            NSArray *array = [self searchVisualSubViewFromView:subView classes: classes];
            if (array.count) {
                [subViews addObjectsFromArray:array];
            }
        }
    }
    return  [subViews copy];
}

- (void)trackGestureRecognizerAppClick:(UIGestureRecognizer *)gestureRecognizer {
    // 手势结束时才采集事件
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) return;
    
    UIView *gestureView = gestureRecognizer.view;
    
    // 指定的 View 不采集手势事件
    if (!gestureView.sensorsdata_canTrack) return;
    
    // 控件是否忽略事件采集
    if (![gestureView conformsToProtocol:@protocol(SAAutoTrackViewProperty)]) return;
    if (gestureView.sensorsdata_isIgnored) return;
    
    // 查找私有系统 View 手势的所在的圈选 View
    NSArray <UIView *>*visualViews = [self searchVisualSubViewFromView:gestureView classes:[SAAutoTrackGestureConfig visualViewsWithHostView:NSStringFromClass(gestureView.class)]];
    CGPoint currentPoint = [gestureRecognizer locationInView:gestureView];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:gestureView];
        if (CGRectContainsPoint(rect, currentPoint)) {
            gestureView = visualView;
            break;
        }
        if (visualView == visualViews.lastObject) {
            return;
        }
    }
    
    // SDK 是否启用, 全埋点点击事件采集是否开启等
    NSDictionary *properties = [SAAutoTrackUtils propertiesWithAutoTrackObject:gestureView];
    if (!properties) return;
    
    // 采集手势事件
    [[SensorsAnalyticsSDK sharedInstance] trackAutoEvent:SA_EVENT_NAME_APP_CLICK properties:properties];
}

@end
