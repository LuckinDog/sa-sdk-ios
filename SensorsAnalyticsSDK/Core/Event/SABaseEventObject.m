//
// SABaseEventObject.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/13.
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

#import "SABaseEventObject.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAPresetProperty.h"
#import "SAFileStore.h"
#import "SAConstants+Private.h"
#import "SALog.h"
#import "SAModuleManager.h"
#import "SARemoteConfigManager.h"
#import "SACommonUtility.h"
#import "SAPropertyValidator.h"
#import "SADateFormatter.h"

@implementation SABaseEventObject

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    if (self = [super init]) {
        self.event = event;
        self.properties = [properties copy];
        self.libObject = [[SAEventLibObject alloc] init];
        [self.libObject configDetailWithEvent:event properties:properties];
        
        self.currentSystemUpTime = NSProcessInfo.processInfo.systemUptime * 1000;
        self.timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
        
        self.dynamicSuperProperties = [SAModuleManager.sharedInstance acquireDynamicSuperProperties];
        
        self.loginId = SensorsAnalyticsSDK.sharedInstance.loginId;
        self.anonymousID = SensorsAnalyticsSDK.sharedInstance.anonymousId;
        self.track_id = @(arc4random());
    }
    return self;
}

- (BOOL)isCanTrack {
    if ([SARemoteConfigManager sharedInstance].isDisableSDK) {
        SALogDebug(@"【remote config】SDK is disabled");
        return NO;
    }
    
    if ([[SARemoteConfigManager sharedInstance] isBlackListContainsEvent:self.event]) {
        SALogDebug(@"【remote config】 %@ is ignored by remote config", self.event);
        return NO;
    }
    return YES;
}

- (BOOL)isValidProperties {
    NSDictionary *temp = [self.properties copy];
    if ([SAPropertyValidator assertProperties:&temp eachProperty:nil]) {
        self.properties = [temp mutableCopy];
        return YES;
    }
    SALogError(@"%@ failed to track event.", self);
    return NO;
}

- (void)addEventPropertiesToDestination:(NSMutableDictionary *)destination {
    // 动态公共属性预处理:
    // 1. 动态公共属性类型校验
    // 2. 动态公共属性内容校验
    // 3. 从静态公共属性中移除 key(忽略大小写) 相同的属性
    NSDictionary *dynamicSuperPropertiesDict = self.dynamicSuperProperties;
    if (dynamicSuperPropertiesDict && [dynamicSuperPropertiesDict isKindOfClass:NSDictionary.class] == NO) {
        SALogDebug(@"dynamicSuperProperties  returned: %@  is not an NSDictionary Obj.", dynamicSuperPropertiesDict);
        dynamicSuperPropertiesDict = nil;
    } else if (![SAPropertyValidator assertProperties:&dynamicSuperPropertiesDict eachProperty:nil]) {
        dynamicSuperPropertiesDict = nil;
    }
    [SAModuleManager.sharedInstance unregisterSameLetterSuperProperties:dynamicSuperPropertiesDict];
    
    // 添加 DeepLink 信息
    [destination addEntriesFromDictionary:SAModuleManager.sharedInstance.latestUtmProperties];
    
    // TODO: 添加预置属性
    [destination addEntriesFromDictionary:@{}];
    
    // 添加公共属性
    NSDictionary *superProperties = [SAModuleManager.sharedInstance currentSuperProperties];
    [destination addEntriesFromDictionary:superProperties];
    
    // 添加动态公共属性
    [destination addEntriesFromDictionary:self.dynamicSuperProperties];
    
    // 从公共属性中更新 lib 节点中的 $app_version 值
    [self.libObject updateAppVersionFromProperties:superProperties];
    
    // TODO: 每次 track 时手机网络状态
    [destination addEntriesFromDictionary:@{}];
    
    // TODO: referrerTitle 处理
//    if (self.configOptions.enableReferrerTitle) {
        // 给 track 和 $sign_up 事件添加 $referrer_title 属性。如果公共属性中存在此属性时会被覆盖，此逻辑优先级更高
//        eventPropertiesDic[kSAEeventPropertyReferrerTitle] = self.referrerManager.referrerTitle;
//    }

    //根据 event 获取事件时长，如返回为 Nil 表示此事件没有相应事件时长，不设置 event_duration 属性
    //为了保证事件时长准确性，当前开机时间需要在 serialQueue 队列外获取，再在此处传入方法内进行计算
    NSNumber *eventDuration = [SAModuleManager.sharedInstance eventDurationFromEventId:self.event currentSysUpTime:self.currentSystemUpTime];
    if (eventDuration) {
        destination[@"event_duration"] = eventDuration;
    }
}

- (void)correctionEventPropertiesWithDestination:(NSMutableDictionary *)destination {
    // 事件、公共属性和动态公共属性都需要支持修改 $project, $token, $time
    self.project = (NSString *)destination[SA_EVENT_COMMON_OPTIONAL_PROPERTY_PROJECT];
    self.token = (NSString *)destination[SA_EVENT_COMMON_OPTIONAL_PROPERTY_TOKEN];
    id originalTime = destination[SA_EVENT_COMMON_OPTIONAL_PROPERTY_TIME];
    if ([originalTime isKindOfClass:NSDate.class]) {
        NSDate *customTime = (NSDate *)originalTime;
        NSInteger customTimeInt = [customTime timeIntervalSince1970] * 1000;
        if (customTimeInt >= SA_EVENT_COMMON_OPTIONAL_PROPERTY_TIME_INT) {
            self.timeStamp = customTimeInt;
        } else {
            SALogError(@"$time error %ld，Please check the value", (long)customTimeInt);
        }
    } else if (originalTime) {
        SALogError(@"$time '%@' invalid，Please check the value", originalTime);
    }
    
    // $project, $token, $time 处理完毕后需要移除
    NSArray<NSString *> *needRemoveKeys = @[SA_EVENT_COMMON_OPTIONAL_PROPERTY_PROJECT,
                                            SA_EVENT_COMMON_OPTIONAL_PROPERTY_TOKEN,
                                            SA_EVENT_COMMON_OPTIONAL_PROPERTY_TIME];
    [destination removeObjectsForKeys:needRemoveKeys];
    
    // 序列化所有 NSDate 类型
    [destination enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSDate class]]) {
            NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@"yyyy-MM-dd HH:mm:ss.SSS"];
            NSString *dateStr = [dateFormatter stringFromDate:(NSDate *)obj];
            destination[key] = dateStr;
        }
    }];

    // TODO: 修正 $device_id，防止用户修改
//    if (destination[SAEventPresetPropertyDeviceID] && self.presetProperty.deviceID) {
//        destination[SAEventPresetPropertyDeviceID] = self.presetProperty.deviceID;
//    }
}

- (NSDictionary *)generateJSONObject {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 添加属性
    [self addEventPropertiesToDestination:properties];
    
    // 添加用户传入的属性
    if ([self.properties isKindOfClass:[NSDictionary class]]) {
        [properties addEntriesFromDictionary:self.properties];
    }
    
    // 属性修正
    [self correctionEventPropertiesWithDestination:properties];
    
    // 组装事件信息
    NSString *eventName = [SAModuleManager.sharedInstance eventNameFromEventId:self.event];
    NSDictionary *jsonObject = @{SA_EVENT_NAME: eventName,
                                 SA_EVENT_PROPERTIES: properties,
                                 SA_EVENT_DISTINCT_ID: SensorsAnalyticsSDK.sharedInstance.distinctId,
                                 SA_EVENT_TIME: @(self.timeStamp),
                                 SA_EVENT_LIB: [self.libObject generateJSONObject],
                                 SA_EVENT_TRACK_ID: self.track_id
                                 };
    return jsonObject;
}

@end
