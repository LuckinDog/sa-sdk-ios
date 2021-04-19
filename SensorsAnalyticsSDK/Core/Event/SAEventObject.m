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
#import "SAIdentifier.h"

@implementation SAEventObject

- (instancetype)initWithEvent:(NSString *)event {
    self = [super init];
    if (self) {
        self.event = event;
    }
    return self;
}

#pragma makr - SAEventBuildStrategy
- (BOOL)addAutomaticProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
    return YES;
}

- (BOOL)addPresetProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
    return YES;
}

- (BOOL)addSuperProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
    // 从公共属性中更新 lib 节点中的 $app_version 值
    id appVersion = properties[SAEventPresetPropertyAppVersion];
    if (appVersion) {
        self.libObject.appVersion = appVersion;
    }
    return YES;
}

- (BOOL)addDeepLinkProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
    return YES;
}

- (BOOL)addCustomProperties:(NSDictionary *)properties {
    if (![super addCustomProperties:properties]) {
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

- (BOOL)addNetworkProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
    return YES;
}

- (BOOL)addReferrerTitleProperty:(NSString *)referrerTitle {
    self.properties[kSAEeventPropertyReferrerTitle] = referrerTitle;
    return YES;
}

- (BOOL)addDurationProperty:(NSNumber *)duration {
    if (duration) {
        self.properties[@"event_duration"] = duration;
    }
    return YES;
}

@end

@implementation SASignUpEventObject

- (instancetype)initWithEvent:(NSString *)event {
    self = [super initWithEvent:event];
    if (self) {
        self.type = kSAEventTypeSignup;
    }
    return self;
}

- (NSDictionary *)generateJSONObject {
    NSMutableDictionary *jsonObject = [[super generateJSONObject] mutableCopy];
    jsonObject[@"original_id"] = SensorsAnalyticsSDK.sharedInstance.anonymousId;
    return [jsonObject copy];
}

@end

@implementation SACustomEventObject

- (instancetype)initWithEvent:(NSString *)event {
    self = [super initWithEvent:event];
    if (self) {
        self.type = kSAEventTypeTrack;
    }
    return self;
}

- (BOOL)addChannelProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
    // 后端匹配逻辑已经不需要 $channel_device_info 信息
    // 这里仍然添加此字段是为了解决服务端版本兼容问题
    self.properties[SA_EVENT_PROPERTY_CHANNEL_INFO] = @"1";
    return YES;
}

@end

@implementation SAAutoTrackEventObject

- (instancetype)initWithEvent:(NSString *)event {
    self = [super initWithEvent:event];
    if (self) {
        self.type = kSAEventTypeTrack;
    }
    return self;
}

- (BOOL)addCustomProperties:(NSDictionary *)properties {
    if (![super addCustomProperties:properties]) {
        return NO;
    }
    self.properties[SAEventPresetPropertyLibMethod] = kSALibMethodAuto;
    self.libObject.method = kSALibMethodAuto;
    return YES;
}

@end

@implementation SAPresetEventObject

- (instancetype)initWithEvent:(NSString *)event {
    self = [super initWithEvent:event];
    if (self) {
        self.type = kSAEventTypeTrack;
    }
    return self;
}

@end

@implementation SAChannelEventObject

- (BOOL)addChannelProperties:(NSDictionary *)properties {
    [self.properties addEntriesFromDictionary:properties];
    // idfa
    NSString *idfa = [SAIdentifier idfa];
    if (idfa) {
        self.properties[SA_EVENT_PROPERTY_CHANNEL_INFO] = [NSString stringWithFormat:@"idfa=%@", idfa];
    } else {
        self.properties[SA_EVENT_PROPERTY_CHANNEL_INFO] = @"";
    }
    return YES;
}

@end
