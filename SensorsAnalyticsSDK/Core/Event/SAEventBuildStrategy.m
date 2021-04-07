//
// SAEventBuildStrategy.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/5.
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

#import "SAEventBuildStrategy.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAValidator.h"

@implementation SAEventBuildStrategy

- (void)addDeeplinkProperties {
    NSDictionary *currentProperties = [self.properties copy];
    if ([SAValidator isValidDictionary:currentProperties]) {
        // 添加 latest utms 属性。用户传入的属性优先级更高。
        NSMutableDictionary *deepLinkInfo = [NSMutableDictionary dictionary];
        [deepLinkInfo addEntriesFromDictionary:[SensorsAnalyticsSDK.sharedInstance latestUtmProperties]];
        [deepLinkInfo addEntriesFromDictionary:currentProperties];
        self.properties = [deepLinkInfo mutableCopy];
    }
}

- (void)addPresetProperties {
    
}

- (void)addSuperProperties {
    
}

- (void)addDynamicProperties {
    
}

@end
