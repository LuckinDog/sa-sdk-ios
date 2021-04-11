//
// SAReferrer.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/4/10.
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

#import "SAReferrer.h"
#import "SAConstants+Private.h"

@interface SAReferrer ()

@property (nonatomic, copy, nullable) NSString *currentTitle;

@end

@implementation SAReferrer

- (NSDictionary *)propertiesWithURL:(NSString *)currentURL
                    eventProperties:(NSDictionary *)eventProperties
                        serialQueue:(dispatch_queue_t)serialQueue
                        enableTitle:(BOOL)isEnableTitle {
    NSString *referrerURL = self.url;
    NSMutableDictionary *newProperties = [NSMutableDictionary dictionaryWithDictionary:eventProperties];
    
    // 客户自定义属性中包含 $url 时，以客户自定义内容为准
    if (!newProperties[kSAEventPropertyScreenURL]) {
        newProperties[kSAEventPropertyScreenURL] = currentURL;
    }
    // 客户自定义属性中包含 $referrer 时，以客户自定义内容为准
    if (referrerURL && !newProperties[kSAEventPropertyScreenReferrerURL]) {
        newProperties[kSAEventPropertyScreenReferrerURL] = referrerURL;
    }
    // $referrer 内容以最终页面浏览事件中的 $url 为准
    self.url = newProperties[kSAEventPropertyScreenURL];
    self.properties = newProperties;

    if (isEnableTitle) {
        dispatch_async(serialQueue, ^{
            [self cacheTitle:newProperties];
        });
    }

    return newProperties;
}

- (void)cacheTitle:(NSDictionary *)properties {
    self.title = self.currentTitle;
    self.currentTitle = properties[kSAEventPropertyTitle];
}

- (void)clear {
    if (self.isClearWhenAppEnd) {
        // 需求层面只需要清除 $referrer，不需要清除 $referrer_title
        self.url = nil;
    }
}

@end
