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
#import "UIGestureRecognizer+AutoTrack.h"

@implementation UIView (SAGesture)

/// 不采集手势事件的 View 类型
+ (NSArray *)sensorsdata_excludeTrackView {
    return @[
                @"_UIContextMenuContainerView",         // UIMenu 的背景视图
                @"WKContentView",                       // WKWebView
                @"UIListContentView",                   // UIDatePicker
                @"_UIDatePickerCalendarTimeLabel",      // UIDatePicker
                @"UICollectionView",                    // UIDatePicker & UIMenu
                @"UISwitchModernVisualElement",         // UISwitch 已经通过 UIControl 的方式采集
                NSStringFromClass(UIPageControl.class), // UIPageControl 已经通过 UIControl 的方式采集
                NSStringFromClass(UITextView.class),    // 不支持 UITextView 事件采集
                NSStringFromClass(UITabBar.class),      // UITabBar 通过 sendAction 方式采集
            ];
}

/// 系统通过手势实现的控件需要采集用户交互事件
/// key: 手势所在 View 的类型;
/// value: View 子视图中能够交互及圈选的控件类型
+ (NSDictionary <NSString *, NSArray <NSString *>*> *)sensorsdata_TrackSystemView {
    return @{
                @"_UIAlertControllerInterfaceActionGroupView":
                    @[@"_UIInterfaceActionCustomViewRepresentationView",
                      @"_UIAlertControllerCollectionViewCell"], // UIAlertController 的手势采集
                @"_UIContextMenuActionsListView":
                    @[@"_UIContextMenuActionsListCell"]         // UIMenu 的手势采集
            };
}

- (BOOL)sensorsdata_canTrack {
    // 指定系统 view 的手势不能被采集
    for (NSString *viewClass in self.class.sensorsdata_excludeTrackView) {
        if ([NSStringFromClass(self.class) isEqualToString:viewClass]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)sensorsdata_isVisualView {
    if (self.userInteractionEnabled) {
        if (self.sensorsdata_canTrack) {
            if (self.sensorsdata_containsTrackGesture) {
                return YES;
            }
            if (self.sensorsdata_isSystemVisualView) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)sensorsdata_isSystemVisualView {
    for (NSArray *visualViews in self.class.sensorsdata_TrackSystemView.allValues) {
        if ([visualViews containsObject:NSStringFromClass(self.class)]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)sensorsdata_containsTrackGesture {
    // 如果手势所在 View, 需要查询子视图, 那么当前视图虽包含手势但应当不可圈选, 而是子视图可圈选
    for (NSString *gestureView in self.class.sensorsdata_TrackSystemView.allKeys) {
        if ([gestureView isEqualToString:NSStringFromClass(self.class)]) {
            if (self.class.sensorsdata_TrackSystemView[gestureView].count) {
                return NO;
            }
        }
    }
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        if (gesture.sensorsdata_canTrack) {
            return YES;
        }
    }
    return NO;
}

- (NSArray <NSString *>*)sensorsdata_systemVisualViewClasses {
    NSString *className = NSStringFromClass(self.class);
    if ([self.class.sensorsdata_TrackSystemView.allKeys containsObject:className]) {
        return self.class.sensorsdata_TrackSystemView[className];
    }
    return @[];
}

@end
