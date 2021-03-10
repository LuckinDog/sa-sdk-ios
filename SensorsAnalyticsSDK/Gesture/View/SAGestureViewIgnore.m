//
// SAGestureViewIgnore.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/18.
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

#import "SAGestureViewIgnore.h"

@implementation SAGestureViewIgnore

+ (BOOL)ignoreWithView:(UIView *)view {
    static dispatch_once_t onceToken;
    static id info = nil;
    dispatch_once(&onceToken, ^{
        NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class] pathForResource:@"SensorsAnalyticsSDK" ofType:@"bundle"]];
        NSString *jsonPath = [sensorsBundle pathForResource:@"sa_autotrack_gestureview_blacklist.json" ofType:nil];
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        if (jsonData) {
            info = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
        }
    });
    if (![info isKindOfClass:NSDictionary.class]) {
        return NO;
    }
    // 公开类名使用 - isKindOfClass: 判断
    id publicClasses = info[@"public"];
    if ([publicClasses isKindOfClass:NSArray.class]) {
        for (NSString *publicClass in (NSArray *)publicClasses) {
            if ([view isKindOfClass:NSClassFromString(publicClass)]) {
                return YES;
            }
        }
    }
    // 私有类名使用字符串匹配判断
    id privateClasses = info[@"private"];
    if ([privateClasses isKindOfClass:NSArray.class]) {
        if ([(NSArray *)privateClasses containsObject:NSStringFromClass(view.class)]) {
            return YES;
        }
    }
    return NO;
}

@end
