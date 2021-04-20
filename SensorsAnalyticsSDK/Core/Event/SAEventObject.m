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
#import "SAPresetProperty.h"
#import "SAValidator.h"
#import "SALog.h"

static NSSet *presetEventNames;

@implementation SAEventObject

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
        self.lib.appVersion = appVersion;
    }
}

- (void)addDeepLinkProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
}

- (void)addCustomProperties:(NSDictionary *)properties error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    [super addCustomProperties:properties error:error];
    if (*error) {
        return;
    }
    
    // 如果传入自定义属性中的 $lib_method 为 String 类型，需要进行修正处理
    id libMethod = self.properties[SAEventPresetPropertyLibMethod];
    if (!libMethod || [libMethod isKindOfClass:NSString.class]) {
        if (![libMethod isEqualToString:kSALibMethodCode] &&
            ![libMethod isEqualToString:kSALibMethodAuto]) {
            libMethod = kSALibMethodCode;
        }
    }
    self.properties[SAEventPresetPropertyLibMethod] = libMethod;
    self.lib.method = libMethod;

    //不考虑 $AppClick 或者 $AppViewScreen 的计时采集，所以这里的 event 不会出现是 trackTimerStart 返回值的情况
    BOOL isAppClick = [self.event isEqualToString:SA_EVENT_NAME_APP_CLICK] && ![SensorsAnalyticsSDK.sharedInstance isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick];
    BOOL isViewScreen = [self.event isEqualToString:SA_EVENT_NAME_APP_VIEW_SCREEN] && ![SensorsAnalyticsSDK.sharedInstance isAutoTrackEventTypeIgnored: SensorsAnalyticsEventTypeAppViewScreen];
    if (isAppClick || isViewScreen) {
        self.lib.detail = [NSString stringWithFormat:@"%@######", properties[SA_EVENT_PROPERTY_SCREEN_NAME] ?: @""];
    }
}

- (void)addNetworkProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
}

- (void)addReferrerTitleProperty:(NSString *)referrerTitle {
    self.properties[kSAEeventPropertyReferrerTitle] = referrerTitle;
}

- (void)addDurationProperty:(NSNumber *)duration {
    if (duration) {
        self.properties[@"event_duration"] = duration;
    }
}

- (void)setEventName:(NSString *)event error:(NSError *__autoreleasing  _Nullable *)error {
    if (event == nil || [event length] == 0) {
        *error = SAPropertyError(20001, @"Event name should not be empty or nil");
        return;
    }
    if (![SAValidator isValidKey:event]) {
        *error = SAPropertyError(20002, @"Event name[%@] not valid", event);
        return;
    }
    self.event = event;
}

@end

@implementation SASignUpEventObject

- (instancetype)init {
    self = [super init];
    if (self) {
        self.type = kSAEventTypeSignup;
    }
    return self;
}

- (NSMutableDictionary *)generateJSONObject {
    NSMutableDictionary *jsonObject = [super generateJSONObject];
    jsonObject[@"original_id"] = self.anonymousId;
    return jsonObject;
}

@end

@implementation SACustomEventObject

- (instancetype)init {
    self = [super init];
    if (self) {
        self.type = kSAEventTypeTrack;
    }
    return self;
}

- (void)addChannelProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
}

- (void)setEventName:(NSString *)event error:(NSError *__autoreleasing  _Nullable *)error {
    [super setEventName:event error:error];
    if (*error) {
        return;
    }
    presetEventNames = [NSSet setWithObjects:
                        SA_EVENT_NAME_APP_START,
                        SA_EVENT_NAME_APP_START_PASSIVELY ,
                        SA_EVENT_NAME_APP_END,
                        SA_EVENT_NAME_APP_VIEW_SCREEN,
                        SA_EVENT_NAME_APP_CLICK,
                        SA_EVENT_NAME_APP_SIGN_UP,
                        SA_EVENT_NAME_APP_CRASHED,
                        SA_EVENT_NAME_APP_REMOTE_CONFIG_CHANGED, nil];
    //事件校验，预置事件提醒
    if ([presetEventNames containsObject:event]) {
        SALogWarn(@"\n【event warning】\n %@ is a preset event name of us, it is recommended that you use a new one", event);
    }
}

@end

@implementation SAAutoTrackEventObject

- (instancetype)init {
    self = [super init];
    if (self) {
        self.type = kSAEventTypeTrack;
    }
    return self;
}

- (void)addCustomProperties:(NSDictionary *)properties error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    [super addCustomProperties:properties error:error];
    if (*error) {
        return;
    }
    self.properties[SAEventPresetPropertyLibMethod] = kSALibMethodAuto;
    self.lib.method = kSALibMethodAuto;
}

@end

@implementation SAPresetEventObject

- (instancetype)init {
    self = [super init];
    if (self) {
        self.type = kSAEventTypeTrack;
    }
    return self;
}

@end
