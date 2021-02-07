//
// SANotificationUtil.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/18.
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

#import "SANotificationUtil.h"
#import "SAAppPushConstants.h"
#import "SALog.h"

@implementation SANotificationUtil

+ (NSDictionary *)propertiesFromUserInfo:(NSDictionary *)userInfo {
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    
    if (userInfo[SA_PUSH_SERVICE_KEY_JPUSH]) {
        properties[SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME] = SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME_JPUSH;
    }
    
    if (userInfo[SA_PUSH_SERVICE_KEY_GETUI]) {
        properties[SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME] = SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME_GETUI;
    }
    
    //SF related properties
    NSString *sfDataString = userInfo[SA_PUSH_SERVICE_KEY_SF];
    if (sfDataString && [sfDataString isKindOfClass:[NSString class]]) {
        NSData *sfData = [userInfo[SA_PUSH_SERVICE_KEY_SF] dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        NSDictionary *sfProperties;
        if (sfData) {
            @try {
                sfProperties = [NSJSONSerialization JSONObjectWithData:sfData options:0 error:&error];
            } @catch (NSException *exception) {
                SALogError(@"%@", exception);
            } @finally {
                if (!error && [sfProperties isKindOfClass:[NSDictionary class]]) {
                    [properties addEntriesFromDictionary:[self propertiesFromSFData:sfProperties]];
                }
            }
            
        }
    }
    
    return [properties copy];
}

+ (NSDictionary *)propertiesFromSFData:(NSDictionary *)sfData {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[SF_MSG_TITLE] = sfData[SF_MSG_TITLE.sensorsdata_sfPushKey];
    properties[SF_PLAN_STRATEGY_ID] = sfData[SF_PLAN_STRATEGY_ID.sensorsdata_sfPushKey];
    properties[SF_CHANNEL_CATEGORY] = sfData[SF_CHANNEL_CATEGORY.sensorsdata_sfPushKey];
    properties[SF_AUDIENCE_ID] = sfData[SF_AUDIENCE_ID.sensorsdata_sfPushKey];
    properties[SF_CHANNEL_ID] = sfData[SF_CHANNEL_ID.sensorsdata_sfPushKey];
    properties[SF_LINK_URL] = sfData[SF_LINK_URL.sensorsdata_sfPushKey];
    properties[SF_PLAN_TYPE] = sfData[SF_PLAN_TYPE.sensorsdata_sfPushKey];
    properties[SF_CHANNEL_SERVICE_NAME] = sfData[SF_CHANNEL_SERVICE_NAME.sensorsdata_sfPushKey];
    properties[SF_MSG_ID] = sfData[SF_MSG_ID.sensorsdata_sfPushKey];
    properties[SF_PLAN_ID] = sfData[SF_PLAN_ID.sensorsdata_sfPushKey];
    properties[SF_STRATEGY_UNIT_ID] = sfData[SF_STRATEGY_UNIT_ID.sensorsdata_sfPushKey];
    properties[SF_ENTER_PLAN_TIME] = sfData[SF_ENTER_PLAN_TIME.sensorsdata_sfPushKey];
    properties[SF_MSG_CONTENT] = sfData[SF_MSG_CONTENT.sensorsdata_sfPushKey];
    return [properties copy];
}

@end

@implementation NSString (SFPushKey)

- (NSString *)sensorsdata_sfPushKey {
    NSString *prefix = @"$";
    if ([self hasPrefix:prefix]) {
        return [self substringFromIndex:[prefix length]];
    }
    return self;
}

@end
