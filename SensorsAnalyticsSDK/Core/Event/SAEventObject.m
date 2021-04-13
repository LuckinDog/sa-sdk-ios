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
#import "SAModuleManager.h"
#import "SARemoteConfigManager.h"
#import "SACommonUtility.h"
#import "SAPropertyValidator.h"

@implementation SAEventObject

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

- (NSDictionary *)generateJSONObject {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[SA_EVENT_LIB] = [self.libObject generateJSONObject];
    return [properties copy];
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

@end

@implementation SASignUpEventObject

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    if (self = [super initWithEvent:event properties:properties]) {
        self.type = kSAEventTypeSignup;
    }
    return self;
}

- (NSDictionary *)generateJSONObject {
    NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:self.properties];
    [self addDeeplinkProperties];
    
    NSString *libMethod = [self.libObject obtainValidLibMethod:self.properties[SAEventPresetPropertyLibMethod]];
    temp[SAEventPresetPropertyLibMethod] = libMethod;
    self.libObject.method = libMethod;
    temp[SA_EVENT_LIB] = [self.libObject generateJSONObject];
    
    [self addPresetProperties];
    [self addSuperProperties];
    [self addDynamicProperties];
    
    return [temp copy];
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

@implementation SAProfileIncrementEventObject

- (BOOL)isValidProperties {
    NSDictionary *temp = [self.properties copy];
    BOOL isValid = [SAPropertyValidator assertProperties:&temp eachProperty:^BOOL(NSString * _Nonnull key, NSString * _Nonnull value) {
        if (![value isKindOfClass:[NSNumber class]]) {
            NSString *errMsg = [NSString stringWithFormat:@"%@ profile_increment value must be NSNumber. got: %@ %@", self, [value class], value];
            SALogError(@"%@", errMsg);
            [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
            return NO;
        }
        return YES;
    }];
    
    if (isValid) {
        self.properties = [temp mutableCopy];
        return YES;
    }
    
    SALogError(@"%@ failed to track event.", self);
    return NO;
}

@end

@implementation SAProfileAppendEventObject

- (BOOL)isValidProperties {
    NSDictionary *temp = [self.properties copy];
    BOOL isValid = [SAPropertyValidator assertProperties:&temp eachProperty:^BOOL(NSString * _Nonnull key, NSString * _Nonnull value) {
        if (![value isKindOfClass:[NSSet class]] && ![value isKindOfClass:[NSArray class]]) {
            NSString *errMsg = [NSString stringWithFormat:@"%@ profile_append value must be NSSet、NSArray. got %@ %@", self, [value  class], value];
            SALogError(@"%@", errMsg);
            [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
            return NO;
        }
        return YES;
    }];
    
    if (isValid) {
        self.properties = [temp mutableCopy];
        return YES;
    }
    
    SALogError(@"%@ failed to track event.", self);
    return NO;
}

@end

@implementation SAH5EventObject

@end
