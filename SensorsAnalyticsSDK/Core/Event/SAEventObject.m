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
#import "SAFileStore.h"
#import "SAModuleManager.h"
#import "SALog.h"

@implementation SAEventObject

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

@end

@implementation SACustomEventObject

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    if (self = [super initWithEvent:event properties:properties]) {
        if (![self isValidNameForTrackEvent:event]) {
            return nil;
        }
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
        self.type = kSAEventTypeTrack;
    }
    return self;
}

@end

@implementation SAH5EventObject

@end
