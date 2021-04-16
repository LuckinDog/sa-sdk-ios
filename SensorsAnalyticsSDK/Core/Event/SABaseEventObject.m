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

- (instancetype)init {
    if (self = [super init]) {
        self.libObject = [[SAEventLibObject alloc] init];
        self.timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
        self.track_id = @(arc4random());
        self.properties = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSDictionary *)generateJSONObject {
    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    eventInfo[SA_EVENT_PROPERTIES] = self.properties;
    eventInfo[SA_EVENT_DISTINCT_ID] = SensorsAnalyticsSDK.sharedInstance.distinctId;
    eventInfo[SA_EVENT_LOGIN_ID] = SensorsAnalyticsSDK.sharedInstance.loginId;
    eventInfo[SA_EVENT_ANONYMOUS_ID] = SensorsAnalyticsSDK.sharedInstance.anonymousId;
    eventInfo[SA_EVENT_TYPE] = self.type;
    eventInfo[SA_EVENT_TIME] = @(self.timeStamp);
    eventInfo[SA_EVENT_LIB] = [self.libObject generateJSONObject];
    eventInfo[SA_EVENT_TRACK_ID] = self.track_id;
    if (self.project) {
        eventInfo[SA_EVENT_PROJECT] = self.project;
    }
    if (self.token) {
        eventInfo[SA_EVENT_TOKEN] = self.token;
    }
    return [eventInfo copy];
}

#pragma makr - SAEventBuildStrategy
- (void)addAutomaticProperties:(NSDictionary *)properties {
}

- (void)addPresetProperties:(NSDictionary *)properties {
}

- (void)addSuperProperties:(NSDictionary *)properties {
}

- (void)addDynamicSuperProperties:(NSDictionary *)properties {
}

- (void)addDeepLinkProperties:(NSDictionary *)properties {
}

- (void)addUserProperties:(NSDictionary *)properties {
    if ([properties isKindOfClass:[NSDictionary class]]) {
        [self.properties addEntriesFromDictionary:[properties copy]];
    }
    // 事件、公共属性和动态公共属性都需要支持修改 $project, $token, $time
    self.project = (NSString *)self.properties[SA_EVENT_COMMON_OPTIONAL_PROPERTY_PROJECT];
    self.token = (NSString *)self.properties[SA_EVENT_COMMON_OPTIONAL_PROPERTY_TOKEN];
    id originalTime = self.properties[SA_EVENT_COMMON_OPTIONAL_PROPERTY_TIME];
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
    [self.properties removeObjectsForKeys:needRemoveKeys];
    
    // 序列化所有 NSDate 类型
    [self.properties enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSDate class]]) {
            NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@"yyyy-MM-dd HH:mm:ss.SSS"];
            NSString *dateStr = [dateFormatter stringFromDate:(NSDate *)obj];
            self.properties[key] = dateStr;
        }
    }];

    // TODO: 修正 $device_id，防止用户修改
    if (self.properties[SAEventPresetPropertyDeviceID] && SensorsAnalyticsSDK.sharedInstance.presetProperty.deviceID) {
        self.properties[SAEventPresetPropertyDeviceID] = SensorsAnalyticsSDK.sharedInstance.presetProperty.deviceID;
    }
    
    // TODO: 处理 lib detail
//    [self.libObject configDetailWithEvent:self.event properties:self.properties];
}

- (void)addNetworkProperties:(NSDictionary *)properties {
}

- (void)addDurationProperty {
}

- (BOOL)isValidProperties:(NSDictionary **)properties {
    if ([SAPropertyValidator assertProperties:properties eachProperty:nil]) {
        return YES;
    }
    SALogError(@"%@ failed to track event.", self);
    return NO;
}

@end
