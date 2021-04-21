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
#import "SAConstants+Private.h"
#import "SAPresetProperty.h"
#import "SALog.h"

@implementation SABaseEventObject

- (instancetype)init {
    self = [super init];
    if (self) {
        _lib = [[SAEventLibObject alloc] init];
        _timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
        _trackId = @(arc4random());
        _properties = [NSMutableDictionary dictionary];
        _propertiesValidator = [[SAPropertyValidator alloc] init];
        _currentSystemUpTime = NSProcessInfo.processInfo.systemUptime * 1000;
    }
    return self;
}

- (NSString *)eventName {
    if (![self.event hasSuffix:kEventIdSuffix]) {
        return self.event;
    }
    //eventId 结构为 {eventName}_D3AC265B_3CC2_4C45_B8F0_3E05A83A9DAE_SATimer，新增后缀长度为 44
    NSString *eventName = [self.event substringToIndex:(self.event.length - 1) - 44];
    return eventName;
}

- (BOOL)isSignUp {
    return [self.type isEqualToString: kSAEventTypeSignup];
}

- (void)isValidEventWithError:(NSError *__autoreleasing  _Nullable *)error {
}

- (NSMutableDictionary *)generateJSONObject {
    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    eventInfo[SA_EVENT_PROPERTIES] = self.properties;
    eventInfo[SA_EVENT_DISTINCT_ID] = self.distinctId;
    eventInfo[SA_EVENT_LOGIN_ID] = self.loginId;
    eventInfo[SA_EVENT_ANONYMOUS_ID] = self.anonymousId;
    eventInfo[SA_EVENT_TYPE] = self.type;
    eventInfo[SA_EVENT_TIME] = @(self.timeStamp);
    eventInfo[SA_EVENT_LIB] = [self.lib generateJSONObject];
    eventInfo[SA_EVENT_TRACK_ID] = self.trackId;
    eventInfo[SA_EVENT_NAME] = self.eventName;
    eventInfo[SA_EVENT_PROJECT] = self.project;
    eventInfo[SA_EVENT_TOKEN] = self.token;
    return eventInfo;
}

#pragma makr - SAEventBuildStrategy
- (void)addChannelProperties:(NSDictionary *)properties {
}

- (void)addAutomaticProperties:(NSDictionary *)properties {
}

- (void)addPresetProperties:(NSDictionary *)properties {
}

- (void)addSuperProperties:(NSDictionary *)properties {
}

- (void)addDeepLinkProperties:(NSDictionary *)properties {
}

- (void)addCustomProperties:(NSDictionary *)properties error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    NSMutableDictionary *props = [self.propertiesValidator validProperties:properties error:error];
    if (*error) {
        return;
    }
    
    [props removeObjectForKey:SAEventPresetPropertyDeviceID];
    [self.properties addEntriesFromDictionary:props];
    
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
            SALogError(@"$time error %ld, Please check the value", (long)customTimeInt);
        }
    } else if (originalTime) {
        SALogError(@"$time '%@' invalid, Please check the value", originalTime);
    }
    
    // $project, $token, $time 处理完毕后需要移除
    NSArray<NSString *> *needRemoveKeys = @[SA_EVENT_COMMON_OPTIONAL_PROPERTY_PROJECT,
                                            SA_EVENT_COMMON_OPTIONAL_PROPERTY_TOKEN,
                                            SA_EVENT_COMMON_OPTIONAL_PROPERTY_TIME];
    [self.properties removeObjectsForKeys:needRemoveKeys];
}

- (void)addNetworkProperties:(NSDictionary *)properties {
}

- (void)addReferrerTitleProperty:(NSString *)referrerTitle {
}

- (void)addDurationProperty:(NSNumber *)duration {
}

@end
