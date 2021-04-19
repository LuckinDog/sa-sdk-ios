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
#import "SAModuleManager.h"
#import "SALog.h"

@implementation SABaseEventObject

- (instancetype)init {
    self = [super init];
    if (self) {
        _libObject = [[SAEventLibObject alloc] init];
        _timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
        _track_id = @(arc4random());
        _properties = [NSMutableDictionary dictionary];
        _propertiesValidator = [[SAPropertyValidator alloc] init];
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
    eventInfo[SA_EVENT_NAME] = self.event;
    
    if (self.project) {
        eventInfo[SA_EVENT_PROJECT] = self.project;
    }
    if (self.token) {
        eventInfo[SA_EVENT_TOKEN] = self.token;
    }
    return [eventInfo copy];
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

- (BOOL)addUserProperties:(NSDictionary *)properties {
    NSError *error = nil;
    NSMutableDictionary *props = [[self.propertiesValidator validProperties:properties error:&error] mutableCopy];
    if (error) {
        SALogError(@"%@", error.localizedDescription);
        [SAModuleManager.sharedInstance showDebugModeWarning:error.localizedDescription];
        return NO;
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
    return YES;
}

- (void)addNetworkProperties:(NSDictionary *)properties {
}

- (void)addDurationProperty {
}

@end
