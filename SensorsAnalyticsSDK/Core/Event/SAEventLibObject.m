//
// SAEventLibObject.m
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

#import "SAEventLibObject.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAPresetProperty.h"
#import "SAValidator.h"
#import "SARemoteConfigManager.h"
#import "SALog.h"

@implementation SAEventLibObject

- (instancetype)init {
    if (self = [super init]) {
        self.lib = @"iOS";
        self.method = kSALibMethodCode;
        self.version = [SensorsAnalyticsSDK.sharedInstance libVersion];
        self.appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        self.detail = nil;
    }
    return self;
}

- (void)setMethod:(NSString *)method {
    if (![SAValidator isValidString:method]) {
        return;
    }
    _method = method;
}

#pragma mark - public
- (NSDictionary *)generateJSONObject {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[SAEventPresetPropertyLib] = self.lib;
    properties[SAEventPresetPropertyLibVersion] = self.version;
    properties[SAEventPresetPropertyAppVersion] = self.appVersion;
    properties[SAEventPresetPropertyLibMethod] = self.method;
    properties[SAEventPresetPropertyLibDetail] = self.detail;
    return [properties copy];
}

- (void)configDetailWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    NSString *libDetail = nil;
    if ([self isAutoTrackEnabled] && properties.count > 0) {
        //不考虑 $AppClick 或者 $AppViewScreen 的计时采集，所以这里的 event 不会出现是 trackTimerStart 返回值的情况
        if ([event isEqualToString:SA_EVENT_NAME_APP_CLICK]) {
            if ([self isAutoTrackEventTypeIgnored: SensorsAnalyticsEventTypeAppClick] == NO) {
                libDetail = [NSString stringWithFormat:@"%@######", properties[SA_EVENT_PROPERTY_SCREEN_NAME] ?: @""];
            }
        } else if ([event isEqualToString:SA_EVENT_NAME_APP_VIEW_SCREEN]) {
            if ([self isAutoTrackEventTypeIgnored: SensorsAnalyticsEventTypeAppViewScreen] == NO) {
                libDetail = [NSString stringWithFormat:@"%@######", properties[SA_EVENT_PROPERTY_SCREEN_NAME] ?: @""];
            }
        }
    }
    self.detail = libDetail;
}

- (NSString *)obtainValidLibMethod:(NSString *)libMethod {
    // 如果传入自定义属性中的 $lib_method 不为 String 类型，直接返回不进行修正处理
    if (libMethod && ![libMethod isKindOfClass:NSString.class]) {
        return libMethod;
    }
    NSString *newLibMethod = libMethod;
    if (![newLibMethod isEqualToString:kSALibMethodCode] && ![newLibMethod isEqualToString:kSALibMethodAuto]) {
        // 自定义属性中的 $lib_method 不为有效值（code 或者 autoTrack），此时使用默认值 code
        newLibMethod = kSALibMethodCode;
    }
    return newLibMethod;
}

#pragma mark - private
- (BOOL)isAutoTrackEnabled {
    if ([SARemoteConfigManager sharedInstance].isDisableSDK) {
        SALogDebug(@"【remote config】SDK is disabled");
        return NO;
    }
    
    NSInteger autoTrackMode = [SARemoteConfigManager sharedInstance].autoTrackMode;
    if (autoTrackMode == kSAAutoTrackModeDefault) {
        // 远程配置不修改现有的 autoTrack 方式
        return (SensorsAnalyticsSDK.configOptions.autoTrackEventType != SensorsAnalyticsEventTypeNone);
    } else {
        // 远程配置修改现有的 autoTrack 方式
        BOOL isEnabled = (autoTrackMode != kSAAutoTrackModeDisabledAll);
        if (!isEnabled) {
            SALogDebug(@"【remote config】AutoTrack Event is ignored by remote config");
        }
        return isEnabled;
    }
}

- (BOOL)isAutoTrackEventTypeIgnored:(SensorsAnalyticsAutoTrackEventType)eventType {
    if ([SARemoteConfigManager sharedInstance].isDisableSDK) {
        SALogDebug(@"【remote config】SDK is disabled");
        return YES;
    }
    
    NSInteger autoTrackMode = [SARemoteConfigManager sharedInstance].autoTrackMode;
    if (autoTrackMode == kSAAutoTrackModeDefault) {
        // 远程配置不修改现有的 autoTrack 方式
        return !(SensorsAnalyticsSDK.configOptions.autoTrackEventType & eventType);
    } else {
        // 远程配置修改现有的 autoTrack 方式
        BOOL isIgnored = (autoTrackMode == kSAAutoTrackModeDisabledAll) ? YES : !(autoTrackMode & eventType);
        if (isIgnored) {
            NSString *ignoredEvent = @"None";
            switch (eventType) {
                case SensorsAnalyticsEventTypeAppStart:
                    ignoredEvent = SA_EVENT_NAME_APP_START;
                    break;
                    
                case SensorsAnalyticsEventTypeAppEnd:
                    ignoredEvent = SA_EVENT_NAME_APP_END;
                    break;
                    
                case SensorsAnalyticsEventTypeAppClick:
                    ignoredEvent = SA_EVENT_NAME_APP_CLICK;
                    break;
                    
                case SensorsAnalyticsEventTypeAppViewScreen:
                    ignoredEvent = SA_EVENT_NAME_APP_VIEW_SCREEN;
                    break;
                    
                default:
                    break;
            }
            SALogDebug(@"【remote config】%@ is ignored by remote config", ignoredEvent);
        }
        return isIgnored;
    }
}

@end
