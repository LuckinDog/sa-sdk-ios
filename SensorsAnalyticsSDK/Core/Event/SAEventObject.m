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
#import "SAFileStore.h"
#import "SAConstants+Private.h"
#import "SALog.h"

@implementation SAEventObject

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    if (self = [super init]) {
        self.event = event;
        self.properties = [NSMutableDictionary dictionaryWithDictionary:properties];
        self.libObject = [[SAEventLibObject alloc] init];
        [self.libObject configDetailWithEvent:event properties:properties];
    }
    return self;
}

- (NSDictionary *)generateJSONObject {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[SA_EVENT_LIB] = [self.libObject generateJSONObject];
    return [properties copy];
}

- (BOOL)isValidNameForTrackEvent:(NSString *)eventName {
    if (eventName == nil || [eventName length] == 0) {
        NSString *errMsg = @"Event name should not be empty or nil";
        SALogError(@"%@", errMsg);
        SensorsAnalyticsDebugMode debugMode = SensorsAnalyticsSDK.sharedInstance.debugMode;
        if (debugMode != SensorsAnalyticsDebugOff) {
            [SensorsAnalyticsSDK.sharedInstance showDebugModeWarning:errMsg withNoMoreButton:YES];
        }
        return NO;
    }
    if (![SensorsAnalyticsSDK.sharedInstance isValidName:eventName]) {
        NSString *errMsg = [NSString stringWithFormat:@"Event name[%@] not valid", eventName];
        SALogError(@"%@", errMsg);
        SensorsAnalyticsDebugMode debugMode = SensorsAnalyticsSDK.sharedInstance.debugMode;
        if (debugMode != SensorsAnalyticsDebugOff) {
            [SensorsAnalyticsSDK.sharedInstance showDebugModeWarning:errMsg withNoMoreButton:YES];
        }
        return NO;
    }
    return YES;
}

@end

@implementation SASignUpEventObject

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    if (self = [super initWithEvent:event properties:properties]) {
        self.type = kSAEventTypeSignup;
    }
    return self;
}

- (NSDictionary *)generateJSONObject {
    [self addDeeplinkProperties];
    
    NSString *libMethod = [self.libObject obtainValidLibMethod:self.properties[SAEventPresetPropertyLibMethod]];
    self.properties[SAEventPresetPropertyLibMethod] = libMethod;
    self.libObject.method = libMethod;
    self.properties[SA_EVENT_LIB] = [self.libObject generateJSONObject];
    
    [self addPresetProperties];
    [self addSuperProperties];
    [self addDynamicProperties];
    
    return [self.properties copy];
}

@end

@implementation SACustomEventObject

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    if (self = [super initWithEvent:event properties:properties]) {
        if (![self isValidNameForTrackEvent:event]) {
            return nil;
        }
        [self addDeeplinkProperties];
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
        if ([presetEventNames containsObject:event]) {
            SALogWarn(@"\n【event warning】\n %@ is a preset event name of us, it is recommended that you use a new one", event);
        }
        
        if (SensorsAnalyticsSDK.sharedInstance.configOptions.enableAutoAddChannelCallbackEvent) {
            // 后端匹配逻辑已经不需要 $channel_device_info 信息
            // 这里仍然添加此字段是为了解决服务端版本兼容问题
            self.properties[SA_EVENT_PROPERTY_CHANNEL_INFO] = @"1";

            BOOL isNotContains = ![self.trackChannelEventNames containsObject:event];
            self.properties[SA_EVENT_PROPERTY_CHANNEL_CALLBACK_EVENT] = @(isNotContains);
            if (isNotContains && event) {
                [self.trackChannelEventNames addObject:event];
                [self archiveTrackChannelEventNames];
            }
        }
        NSString *libMethod = [self.libObject obtainValidLibMethod:self.properties[SAEventPresetPropertyLibMethod]];
        self.properties[SAEventPresetPropertyLibMethod] = libMethod;
        self.libObject.method = libMethod;
        self.type = kSAEventTypeTrack;
    }
    return self;
}

- (void)archiveTrackChannelEventNames {
    [SAFileStore archiveWithFileName:SA_EVENT_PROPERTY_CHANNEL_INFO value:self.trackChannelEventNames];
}

@end

@implementation SAAutoTrackEventObject

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    if (self = [super initWithEvent:event properties:properties]) {
        if (![self isValidNameForTrackEvent:event]) {
            return nil;
        }
        [self addDeeplinkProperties];
        self.properties[SAEventPresetPropertyLibMethod] = kSALibMethodAuto;
        self.libObject.method = kSALibMethodAuto;
        self.type = kSAEventTypeTrack;
    }
    return self;
}

@end

@implementation SAPresetEventObject

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    if (self = [super initWithEvent:event properties:properties]) {
        if (![self isValidNameForTrackEvent:event]) {
            return nil;
        }
        [self addDeeplinkProperties];
        NSString *libMethod = [self.libObject obtainValidLibMethod:self.properties[SAEventPresetPropertyLibMethod]];
        self.properties[SAEventPresetPropertyLibMethod] = libMethod;
        self.libObject.method = libMethod;
        self.type = kSAEventTypeTrack;
    }
    return self;
}

@end

@implementation SAProfileEventObject

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    if (self = [super initWithEvent:event properties:properties]) {
        self.libObject.method = kSALibMethodCode;
    }
    return self;
}

@end

@implementation SAH5EventObject

@end
