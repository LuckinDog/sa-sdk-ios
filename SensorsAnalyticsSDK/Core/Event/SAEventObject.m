//
// SAEventObject.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/6.
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

#import "SAEventObject.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAPropertyValidator.h"
#import "SAModuleManager.h"

@implementation SAEventObject

- (instancetype)initWithEvent:(NSString *)event {
    if (self = [super init]) {
        self.event = event;
        self.currentSystemUpTime = NSProcessInfo.processInfo.systemUptime * 1000;
    }
    return self;
}

- (NSDictionary *)generateJSONObject {
    NSMutableDictionary *jsonObject = [[super generateJSONObject] mutableCopy];
    NSString *eventName = [SAModuleManager.sharedInstance eventNameFromEventId:self.event];
    jsonObject[SA_EVENT_NAME] = eventName;
    return [jsonObject copy];
}

#pragma makr - SAEventBuildStrategy
- (void)addAutomaticProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
}

- (void)addPresetProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
}

- (void)addSuperProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
    // 从公共属性中更新 lib 节点中的 $app_version 值
    id appVersion = properties[SAEventPresetPropertyAppVersion];
    if (appVersion) {
        self.libObject.appVersion = appVersion;
    }
}

- (void)addDynamicSuperProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
}

- (void)addDeepLinkProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
}

- (BOOL)addUserProperties:(NSDictionary *)properties {
    if (![super addUserProperties:properties]) {
        return NO;
    }
    
    // 如果传入自定义属性中的 $lib_method 为 String 类型，需要进行修正处理
    id libMethod = self.properties[SAEventPresetPropertyLibMethod];
    if (libMethod) {
        if ([libMethod isKindOfClass:NSString.class]) {
            if ([libMethod isEqualToString:kSALibMethodCode] ||
                [libMethod isEqualToString:kSALibMethodAuto]) {
                self.libObject.method = libMethod;
            } else {
                // 自定义属性中的 $lib_method 不为有效值（code 或者 autoTrack），此时使用默认值 code
                self.properties[SAEventPresetPropertyLibMethod] = kSALibMethodCode;
            }
        }
    } else {
        self.properties[SAEventPresetPropertyLibMethod] = kSALibMethodCode;
    }
    
    NSString *libDetail = nil;
    if ([SensorsAnalyticsSDK.sharedInstance isAutoTrackEnabled] && properties.count > 0) {
        //不考虑 $AppClick 或者 $AppViewScreen 的计时采集，所以这里的 event 不会出现是 trackTimerStart 返回值的情况
        if ([self.event isEqualToString:SA_EVENT_NAME_APP_CLICK]) {
            if (![SensorsAnalyticsSDK.sharedInstance isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
                libDetail = [NSString stringWithFormat:@"%@######", properties[SA_EVENT_PROPERTY_SCREEN_NAME] ?: @""];
            }
        } else if ([self.event isEqualToString:SA_EVENT_NAME_APP_VIEW_SCREEN]) {
            if (![SensorsAnalyticsSDK.sharedInstance isAutoTrackEventTypeIgnored: SensorsAnalyticsEventTypeAppViewScreen]) {
                libDetail = [NSString stringWithFormat:@"%@######", properties[SA_EVENT_PROPERTY_SCREEN_NAME] ?: @""];
            }
        }
    }
    self.libObject.detail = libDetail;
    return YES;
}

- (void)addNetworkProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
}

- (void)addDurationProperty {
    // 根据 event 获取事件时长，如返回为 Nil 表示此事件没有相应事件时长，不设置 event_duration 属性
    // 为了保证事件时长准确性，当前开机时间需要在 serialQueue 队列外获取，再在此处传入方法内进行计算
    NSNumber *eventDuration = [SAModuleManager.sharedInstance eventDurationFromEventId:self.event currentSysUpTime:self.currentSystemUpTime];
    if (eventDuration) {
        self.properties[@"event_duration"] = eventDuration;
    }
}

@end

@implementation SASignUpEventObject

- (instancetype)initWithEvent:(NSString *)event {
    if (self = [super initWithEvent:event]) {
        self.type = kSAEventTypeSignup;
    }
    return self;
}

- (NSDictionary *)generateJSONObject {
    NSMutableDictionary *jsonObject = [[super generateJSONObject] mutableCopy];
    NSString *eventName = [SAModuleManager.sharedInstance eventNameFromEventId:self.event];
    jsonObject[SA_EVENT_NAME] = eventName;
    jsonObject[@"original_id"] = SensorsAnalyticsSDK.sharedInstance.anonymousId;
    return [jsonObject copy];
}

@end

@implementation SACustomEventObject

- (instancetype)initWithEvent:(NSString *)event {
    if (self = [super initWithEvent:event]) {
        self.type = kSAEventTypeTrack;
    }
    return self;
}

- (void)addChannelProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
}

@end

@implementation SAAutoTrackEventObject

- (instancetype)initWithEvent:(NSString *)event {
    if (self = [super initWithEvent:event]) {
        self.type = kSAEventTypeTrack;
    }
    return self;
}

- (BOOL)addUserProperties:(NSDictionary *)properties {
    if (![super addUserProperties:properties]) {
        return NO;
    }
    self.properties[SAEventPresetPropertyLibMethod] = kSALibMethodAuto;
    self.libObject.method = kSALibMethodAuto;
    return YES;
}

@end

@implementation SAPresetEventObject

- (instancetype)initWithEvent:(NSString *)event {
    if (self = [super initWithEvent:event]) {
        self.type = kSAEventTypeTrack;
    }
    return self;
}

@end

@implementation SAH5EventObject

@end
