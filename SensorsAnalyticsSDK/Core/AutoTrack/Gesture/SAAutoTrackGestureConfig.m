//
// SAAutoTrackGestureConfig.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/1/27.
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

#import "SAAutoTrackGestureConfig.h"
#import "SALog.h"

static NSDictionary *_gestureConfig = nil;

@implementation SAAutoTrackGestureConfig

/// 加载配置文件
+ (void)loadFileData {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class] pathForResource:@"SensorsAnalyticsSDK.bundle" ofType:nil]];
        NSString *jsonPath = [sensorsBundle pathForResource:@"sa_autotrack_gesture_config.json" ofType:nil];
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        @try {
            _gestureConfig = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
        } @catch(NSException *exception) {
            SALogError(@"%@ error: %@", self, exception);
        }
    });
}

/// 获取 support 节点信息
+ (NSDictionary <NSString *, NSDictionary *>*)supportInfo {
    [self loadFileData];
    return _gestureConfig[@"support"];
}

/// 获取 forbidden 节点信息
+ (NSDictionary <NSString *, NSArray *>*)forbiddenInfo {
    [self loadFileData];
    return _gestureConfig[@"forbidden"];
}

/// 获取支持采集的手势集合
+ (NSArray <NSString *>*)supportGestures {
    return [self supportInfo].allKeys;
}

/// 获取手势所在 View 需要特殊处理的私有 View 信息
+ (NSArray <NSDictionary <NSString *, NSDictionary *>*>*)gestureSystemViewInfo {
    NSMutableArray *resutl = [NSMutableArray array];
    for (NSString *key in self.supportInfo.allKeys) {
        NSDictionary *dic = self.supportInfo[key];
        if (dic.allKeys.count) {
            [resutl addObject:dic];
        }
    }
    return resutl;
}

/// 获取禁止采集手势的 View 集合
+ (NSArray <NSString *>*)forbiddenViews {
    return [self forbiddenInfo][@"view"];
}

@end
