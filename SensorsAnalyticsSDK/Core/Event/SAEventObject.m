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

- (instancetype)initWithProperties:(NSDictionary *)properties event:(NSString *)event {
    if (self = [super initWithProperties:properties]) {
        self.event = event;
        self.loginId = SensorsAnalyticsSDK.sharedInstance.loginId;
        self.anonymousID = SensorsAnalyticsSDK.sharedInstance.anonymousId;
    }
    return self;
}

- (NSDictionary *)generateJSONObject {
    NSMutableDictionary *properties = self.resultProperties;
    // 添加用户传入的属性
    if ([self.properties isKindOfClass:[NSDictionary class]]) {
        [self.libObject configDetailWithEvent:self.event properties:self.properties];
        [properties addEntriesFromDictionary:self.properties];
    }
    
    // 属性修正
    [self correctionEventPropertiesWithDestination:properties];
    
    // 组装事件信息
    NSString *eventName = [SAModuleManager.sharedInstance eventNameFromEventId:self.event];
    NSMutableDictionary *jsonObject = [@{
                                        SA_EVENT_NAME: eventName,
                                        SA_EVENT_PROPERTIES: properties,
                                        } mutableCopy];
    // 添加事件信息
    [self addEventInfoToDestination:jsonObject];
    
    return [jsonObject copy];
}

- (BOOL)isValidNameForTrackEvent:(NSString *)eventName {
    if (eventName == nil || [eventName length] == 0) {
        NSString *errMsg = @"Event name should not be empty or nil";
        SALogError(@"%@", errMsg);
        SensorsAnalyticsDebugMode debugMode = SAModuleManager.sharedInstance.debugMode;
        if (debugMode != SensorsAnalyticsDebugOff) {
            [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
        }
        return NO;
    }
    if (![SensorsAnalyticsSDK.sharedInstance isValidName:eventName]) {
        NSString *errMsg = [NSString stringWithFormat:@"Event name[%@] not valid", eventName];
        SALogError(@"%@", errMsg);
        SensorsAnalyticsDebugMode debugMode = SAModuleManager.sharedInstance.debugMode;
        if (debugMode != SensorsAnalyticsDebugOff) {
            [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
        }
        return NO;
    }
    return YES;
}

#pragma makr - SAEventBuildStrategy
- (void)addPresetProperties:(NSDictionary *)properties {
    [self.resultProperties addEntriesFromDictionary:properties];
}

- (void)addSuperProperties:(NSDictionary *)properties {
    [self.resultProperties addEntriesFromDictionary:properties];
    // 从公共属性中更新 lib 节点中的 $app_version 值
    [self.libObject updateAppVersionFromProperties:properties];
}

- (void)addDynamicSuperProperties:(NSDictionary *)properties {
    [self.resultProperties addEntriesFromDictionary:properties];
}

- (void)addDeepLinkProperties:(NSDictionary *)properties {
    [self.resultProperties addEntriesFromDictionary:properties];
    NSString *libMethod = [self.libObject obtainValidLibMethod:properties[SAEventPresetPropertyLibMethod]];
    self.resultProperties[SAEventPresetPropertyLibMethod] = libMethod;
    self.libObject.method = libMethod;
}

- (void)addNetworkProperties:(NSDictionary *)properties {
    [self.resultProperties addEntriesFromDictionary:properties];
}

- (void)addDurationWithEvent:(NSString *)event {
    // 根据 event 获取事件时长，如返回为 Nil 表示此事件没有相应事件时长，不设置 event_duration 属性
    // 为了保证事件时长准确性，当前开机时间需要在 serialQueue 队列外获取，再在此处传入方法内进行计算
    NSNumber *eventDuration = [SAModuleManager.sharedInstance eventDurationFromEventId:event currentSysUpTime:self.currentSystemUpTime];
    if (eventDuration) {
        self.resultProperties[@"event_duration"] = eventDuration;
    }
}

@end

@implementation SASignUpEventObject

- (instancetype)initWithProperties:(NSDictionary *)properties event:(NSString *)event {
    if (self = [super initWithProperties:properties event:event]) {
        self.type = kSAEventTypeSignup;
    }
    return self;
}


- (NSDictionary *)generateJSONObject {
    NSMutableDictionary *properties = self.resultProperties;
    // 添加用户传入的属性
    if ([self.properties isKindOfClass:[NSDictionary class]]) {
        [self.libObject configDetailWithEvent:self.event properties:self.properties];
        [properties addEntriesFromDictionary:self.properties];
    }
    
    // 属性修正
    [self correctionEventPropertiesWithDestination:properties];
    
    // 组装事件信息
    NSString *eventName = [SAModuleManager.sharedInstance eventNameFromEventId:self.event];
    NSMutableDictionary *jsonObject = [@{
                                        SA_EVENT_NAME: eventName,
                                        SA_EVENT_PROPERTIES: properties,
                                        @"original_id": SensorsAnalyticsSDK.sharedInstance.anonymousId
                                        } mutableCopy];
    
    [self addEventInfoToDestination:jsonObject];
    return jsonObject;
}

@end

@implementation SACustomEventObject

- (instancetype)initWithProperties:(NSDictionary *)properties event:(NSString *)event {
    if (self = [super initWithProperties:properties event:event]) {
        if (![self isValidNameForTrackEvent:event]) {
            return nil;
        }
        self.type = kSAEventTypeTrack;
    }
    return self;
}

- (BOOL)isCanTrack {
    BOOL canTrack = YES;
    NSSet *presetEventNames = [NSSet setWithObjects:
                               SA_EVENT_NAME_APP_START,
                               SA_EVENT_NAME_APP_START_PASSIVELY ,
                               SA_EVENT_NAME_APP_END,
                               SA_EVENT_NAME_APP_VIEW_SCREEN,
                               SA_EVENT_NAME_APP_CLICK,
                               SA_EVENT_NAME_APP_SIGN_UP,
                               SA_EVENT_NAME_APP_CRASHED,
                               SA_EVENT_NAME_APP_REMOTE_CONFIG_CHANGED, nil];
    
    //事件校验，预置事件提醒
    if ([presetEventNames containsObject:self.event]) {
        SALogWarn(@"\n【event warning】\n %@ is a preset event name of us, it is recommended that you use a new one", self.event);
    }
    return canTrack;
}

- (void)archiveTrackChannelEventNames {
    [SAFileStore archiveWithFileName:SA_EVENT_PROPERTY_CHANNEL_INFO value:self.trackChannelEventNames];
}

@end

@implementation SAAutoTrackEventObject

- (instancetype)initWithProperties:(NSDictionary *)properties event:(NSString *)event {
    if (self = [super initWithProperties:properties event:event]) {
        if (![self isValidNameForTrackEvent:event]) {
            return nil;
        }
        self.libObject.method = kSALibMethodAuto;
        self.type = kSAEventTypeTrack;
    }
    return self;
}

@end

@implementation SAPresetEventObject

- (instancetype)initWithProperties:(NSDictionary *)properties event:(NSString *)event {
    if (self = [super initWithProperties:properties event:event]) {
        if (![self isValidNameForTrackEvent:event]) {
            return nil;
        }
        self.type = kSAEventTypeTrack;
    }
    return self;
}

@end

@implementation SAH5EventObject

@end
