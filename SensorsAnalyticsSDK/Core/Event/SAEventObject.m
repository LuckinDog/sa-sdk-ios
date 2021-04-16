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
#import "SARemoteConfigManager.h"
#import "SAPropertyValidator.h"
#import "SADateFormatter.h"
#import "SAFileStore.h"
#import "SAModuleManager.h"
#import "SALog.h"

@implementation SAEventObject

- (instancetype)initWithEvent:(NSString *)event {
    if (self = [super init]) {
        self.event = event;
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
    [self.libObject updateAppVersionFromProperties:properties];
}

- (void)addDynamicSuperProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
}

- (void)addDeepLinkProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
    NSString *libMethod = [self.libObject obtainValidLibMethod:properties[SAEventPresetPropertyLibMethod]];
    self.properties[SAEventPresetPropertyLibMethod] = libMethod;
    self.libObject.method = libMethod;
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

- (void)archiveTrackChannelEventNames {
    [SAFileStore archiveWithFileName:SA_EVENT_PROPERTY_CHANNEL_INFO value:self.trackChannelEventNames];
}

- (NSDictionary *)generateJSONObject {
    NSMutableDictionary *properties = self.properties;
    
    if (self.enableAutoAddChannelCallbackEvent) {
        // 后端匹配逻辑已经不需要 $channel_device_info 信息
        // 这里仍然添加此字段是为了解决服务端版本兼容问题
        properties[SA_EVENT_PROPERTY_CHANNEL_INFO] = @"1";

        BOOL isNotContains = ![self.trackChannelEventNames containsObject:self.event];
        properties[SA_EVENT_PROPERTY_CHANNEL_CALLBACK_EVENT] = @(isNotContains);
        if (isNotContains && self.event) {
            [self.trackChannelEventNames addObject:self.event];
            [self archiveTrackChannelEventNames];
        }
    }
    
    NSMutableDictionary *jsonObject = [[super generateJSONObject] mutableCopy];
    NSString *eventName = [SAModuleManager.sharedInstance eventNameFromEventId:self.event];
    jsonObject[SA_EVENT_NAME] = eventName;
    jsonObject[@"original_id"] = SensorsAnalyticsSDK.sharedInstance.anonymousId;
    return [jsonObject copy];
}

@end

@implementation SAAutoTrackEventObject

- (instancetype)initWithEvent:(NSString *)event {
    if (self = [super initWithEvent:event]) {
        self.type = kSAEventTypeTrack;
    }
    return self;
}

- (void)addDeepLinkProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
    self.properties[SAEventPresetPropertyLibMethod] = kSALibMethodAuto;
    self.libObject.method = kSALibMethodAuto;
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
