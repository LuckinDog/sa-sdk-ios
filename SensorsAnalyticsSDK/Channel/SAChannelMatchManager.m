//
// SAChannelMatchManager.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/8/29.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAChannelMatchManager.h"
#import "SAConstants+Private.h"
#import "SAIdentifier.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAValidator.h"

@interface SAChannelMatchManager ()

@property (nonatomic, assign) BOOL deviceEmpty;
@property (nonatomic, assign) BOOL appInstalled;

@end

@implementation SAChannelMatchManager

- (void)trackInstallation:(NSString *)event properties:(NSDictionary *)propertyDict disableCallback:(BOOL)disableCallback {

        NSString *userDefaultsKey = disableCallback ? SA_HAS_TRACK_INSTALLATION_DISABLE_CALLBACK : SA_HAS_TRACK_INSTALLATION;
        BOOL hasTrackInstallation = [[NSUserDefaults standardUserDefaults] boolForKey:userDefaultsKey];
        if (hasTrackInstallation) {
            return;
        }

        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:userDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];

        if (!hasTrackInstallation) {

            // 追踪渠道是特殊功能，需要同时发送 track 和 profile_set_once
            NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
            NSString *idfa = [SAIdentifier idfa];
            if (idfa != nil) {
                [properties setValue:[NSString stringWithFormat:@"idfa=%@", idfa] forKey:SA_EVENT_PROPERTY_APP_INSTALL_SOURCE];
            } else {
                [properties setValue:@"" forKey:SA_EVENT_PROPERTY_APP_INSTALL_SOURCE];
            }

            if (disableCallback) {
                [properties setValue:@YES forKey:SA_EVENT_PROPERTY_APP_INSTALL_DISABLE_CALLBACK];
            }

            __block NSString *userAgent = [propertyDict objectForKey:SA_EVENT_PROPERTY_APP_USER_AGENT];
            dispatch_block_t trackInstallationBlock = ^{
                if (userAgent) {
                    [properties setValue:userAgent forKey:SA_EVENT_PROPERTY_APP_USER_AGENT];
                }

                // 添加 deepLink 来源渠道信息
                // 来源渠道消息只需要添加到 event 事件中，这里使用一个新的字典来添加 latest_utms 参数
                NSMutableDictionary *eventProperties = [properties mutableCopy];
                [eventProperties addEntriesFromDictionary:[self.linkHandler latestUtmProperties]];
                if ([SAValidator isValidDictionary:propertyDict]) {
                    [eventProperties addEntriesFromDictionary:propertyDict];
                }
                // 先发送 track
                [[SensorsAnalyticsSDK sharedInstance] track:event withProperties:eventProperties withTrackType:SensorsAnalyticsTrackTypeAuto];

                // 再发送 profile_set_once
                // profile 事件不需要添加来源渠道信息，这里只追加用户传入的 propertyDict 和时间属性
                NSMutableDictionary *profileProperties = [properties mutableCopy];
                if ([SAValidator isValidDictionary:propertyDict]) {
                    [profileProperties addEntriesFromDictionary:propertyDict];
                }
                [profileProperties setValue:[NSDate date] forKey:SA_EVENT_PROPERTY_APP_INSTALL_FIRST_VISIT_TIME];
                if (self.configOptions.enableMultipleChannelMatch) {
                    [[SensorsAnalyticsSDK sharedInstance] set:profileProperties];
                } else {
                    [[SensorsAnalyticsSDK sharedInstance] setOnce:profileProperties];
                }
                [[SensorsAnalyticsSDK sharedInstance] flush];
            };

            if (userAgent.length == 0) {
                [[SensorsAnalyticsSDK sharedInstance] loadUserAgentWithCompletion:^(NSString *ua) {
                    userAgent = ua;
                    trackInstallationBlock();
                }];
            } else {
                trackInstallationBlock();
            }
        }
}

@end
