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
#import "SAAutoTrackGestureConfig.h"

@implementation UIView (SAGesture)

- (BOOL)sensorsdata_canTrack {
    return ![SAAutoTrackGestureConfig.forbiddenViews containsObject:NSStringFromClass(self.class)];
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
    for (NSDictionary *visualViewInfo in SAAutoTrackGestureConfig.gestureSystemViewInfo) {
        for (NSArray <NSString *>*value in visualViewInfo.allValues) {
            if ([value containsObject:NSStringFromClass(self.class)]) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)sensorsdata_containsTrackGesture {
    // 如果手势所在 View, 需要查询子视图, 那么当前视图虽包含手势但应当不可圈选, 而是子视图可圈选
    for (NSDictionary *gestureViewInfo in SAAutoTrackGestureConfig.gestureSystemViewInfo) {
        if (gestureViewInfo[NSStringFromClass(self.class)]) {
            return NO;
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
    NSArray <NSDictionary <NSString *, NSDictionary *>*>*array = SAAutoTrackGestureConfig.gestureSystemViewInfo;
    for (NSDictionary *gestureViewInfo in array) {
        if ([gestureViewInfo.allKeys containsObject:className]) {
            return gestureViewInfo[className];
        }
    }
    return @[];
}

@end
