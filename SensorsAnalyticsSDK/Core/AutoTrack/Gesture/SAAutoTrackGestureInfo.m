//
// SAAutoTrackGestureInfo.m
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

#import "SAAutoTrackGestureInfo.h"
#import "SALog.h"

static NSDictionary *fileInfo = nil;

@implementation SAAutoTrackGestureInfo

+ (void)loadFileData {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class] pathForResource:@"SensorsAnalyticsSDK.bundle" ofType:nil]];
        NSString *jsonPath = [sensorsBundle pathForResource:@"sa_autotrack_gesture_info.json" ofType:nil];
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        @try {
            fileInfo = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
        } @catch(NSException *exception) {
            SALogError(@"%@ error: %@", self, exception);
        }
    });
}

+ (NSDictionary <NSString *, NSDictionary *>*)supportInfo {
    [self loadFileData];
    return fileInfo[@"support"];
}

+ (NSDictionary <NSString *, NSArray *>*)forbiddenInfo {
    [self loadFileData];
    return fileInfo[@"forbidden"];
}

+ (NSArray <NSString *>*)supportGestures {
    return [self supportInfo].allKeys;
}

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

+ (NSArray <NSString *>*)forbiddenViews {
    return [self forbiddenInfo][@"view"];
}

+ (NSDictionary <NSString *, NSArray *>*)gestureInfo:(NSString *)name {
    return [self supportInfo][name];
}

@end
