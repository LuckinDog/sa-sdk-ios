//
// SAAppStartTracker.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/4/2.
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

#import "SAAppStartTracker.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"

// App 启动标记
static NSString * const kSAHasLaunchedOnce = @"HasLaunchedOnce";
// App 首次启动
static NSString * const kSAEventPropertyAppFirstStart = @"$is_first_time";
// App 是否从后台恢复
static NSString * const kSAEventPropertyResumeFromBackground = @"$resume_from_background";

@implementation SAAppStartTracker

- (BOOL)isFirstAppStart {
    NSUserDefaults *standard = [NSUserDefaults standardUserDefaults];
    if (![standard boolForKey:kSAHasLaunchedOnce]) {
        [standard setBool:YES forKey:kSAHasLaunchedOnce];
        [standard synchronize];
        return YES;
    }
    return NO;
}

- (void)trackAppStartWithRelauch:(BOOL)isRelaunched utmProperties:(NSDictionary *)utmProperties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    if (isRelaunched) {
        properties[kSAEventPropertyAppFirstStart] = @(NO);
        properties[kSAEventPropertyResumeFromBackground] = @(YES);
    } else {
        properties[kSAEventPropertyAppFirstStart] = @([self isFirstAppStart]);
        properties[kSAEventPropertyResumeFromBackground] = @(NO);
    }
    //添加 deeplink 相关渠道信息，可能不存在
    [properties addEntriesFromDictionary:utmProperties];
    [SensorsAnalyticsSDK.sharedInstance trackAutoEvent:kSAEventNameAppStart properties:properties];
}

- (void)trackAppStartPassivelyWithUtmProperties:(NSDictionary *)utmProperties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[kSAEventPropertyAppFirstStart] = @([self isFirstAppStart]);
    properties[kSAEventPropertyResumeFromBackground] = @(NO);
    //添加 deeplink 相关渠道信息，可能不存在
    [properties addEntriesFromDictionary:utmProperties];
    [SensorsAnalyticsSDK.sharedInstance trackAutoEvent:kSAEventNameAppStartPassively properties:properties];
}

@end
