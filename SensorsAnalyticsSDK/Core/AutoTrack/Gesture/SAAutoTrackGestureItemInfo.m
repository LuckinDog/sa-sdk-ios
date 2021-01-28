//
// SAAutoTrackGestureItemInfo.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/1/28.
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

#import "SAAutoTrackGestureItemInfo.h"

@implementation SAAutoTrackGestureItemInfo

- (instancetype)initWithConfig:(NSDictionary *)config {
    if (self = [super init]) {
        self.type = config[@"type"];
        self.hostView = config[@"hostView"];
        self.visualViews = config[@"visualViews"];
    }
    return self;
}

+ (NSArray <SAAutoTrackGestureItemInfo *>*)itemsFromInfo:(NSArray <NSDictionary *>*)info {
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *config in info) {
        SAAutoTrackGestureItemInfo *item = [[SAAutoTrackGestureItemInfo alloc] initWithConfig:config];
        [result addObject:item];
    }
    return [result copy];
}

+ (NSArray <NSString *>*)typesFromItems:(NSArray <SAAutoTrackGestureItemInfo *>*)items {
    NSMutableArray *result = [NSMutableArray array];
    for (SAAutoTrackGestureItemInfo *item in items) {
        [result addObject:item.type];
    }
    return [result copy];
}

+ (NSArray <NSString *>*)hostViewsFromItems:(NSArray <SAAutoTrackGestureItemInfo *>*)items {
    NSMutableArray *result = [NSMutableArray array];
    for (SAAutoTrackGestureItemInfo *item in items) {
        [result addObject:item.hostView];
    }
    return [result copy];
}

@end
