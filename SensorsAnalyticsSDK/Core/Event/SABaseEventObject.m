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

- (instancetype)initWithProperties:(NSDictionary *)properties {
    if (self = [super init]) {
        self.properties = [properties copy];
        
        self.libObject = [[SAEventLibObject alloc] init];
        
        self.currentSystemUpTime = NSProcessInfo.processInfo.systemUptime * 1000;
        
        self.timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
        
        self.track_id = @(arc4random());
    }
    return self;
}

- (BOOL)isCanTrack {
    if ([SARemoteConfigManager sharedInstance].isDisableSDK) {
        SALogDebug(@"【remote config】SDK is disabled");
        return NO;
    }
    return YES;
}

- (void)addEventInfoToDestination:(NSMutableDictionary *)destination {
    NSDictionary *eventInfo = @{SA_EVENT_DISTINCT_ID: SensorsAnalyticsSDK.sharedInstance.distinctId,
                                SA_EVENT_LOGIN_ID: SensorsAnalyticsSDK.sharedInstance.loginId,
                                SA_EVENT_ANONYMOUS_ID: SensorsAnalyticsSDK.sharedInstance.anonymousId,
                                SA_EVENT_TIME: @(self.timeStamp),
                                SA_EVENT_LIB: [self.libObject generateJSONObject],
                                SA_EVENT_TRACK_ID: self.track_id
                                };
    [destination addEntriesFromDictionary:eventInfo];
    if (self.project) {
        destination[SA_EVENT_PROJECT] = self.project;
    }
    if (self.token) {
        destination[SA_EVENT_TOKEN] = self.token;
    }
}

- (NSDictionary *)generateJSONObject {
    return self.properties;
}

@end
