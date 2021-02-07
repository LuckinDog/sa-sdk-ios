//
// SAAppPushConstants.h
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

#import <Foundation/Foundation.h>

//AppPush Notification related
extern NSString * const SA_EVENT_NAME_APP_NOTIFICATION_CLICK;
extern NSString * const SA_EVENT_PROPERTY_NOTIFICATION_TITLE;
extern NSString * const SA_EVENT_PROPERTY_NOTIFICATION_CONTENT;
extern NSString * const SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME;
extern NSString * const SA_EVENT_PROPERTY_NOTIFICATION_CHANNEL;
extern NSString * const SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME_LOCAL;
extern NSString * const SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME_JPUSH;
extern NSString * const SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME_GETUI;
extern NSString * const SA_EVENT_PROPERTY_NOTIFICATION_CHANNEL_APPLE;

//identifier for third part push service
extern NSString * const SA_PUSH_SERVICE_KEY_JPUSH;
extern NSString * const SA_PUSH_SERVICE_KEY_GETUI;
extern NSString * const SA_PUSH_SERVICE_KEY_SF;

//APNS related key
extern NSString * const SA_PUSH_APPLE_USER_INFO_KEY_APS;
extern NSString * const SA_PUSH_APPLE_USER_INFO_KEY_ALERT;
extern NSString * const SA_PUSH_APPLE_USER_INFO_KEY_TITLE;
extern NSString * const SA_PUSH_APPLE_USER_INFO_KEY_BODY;

//sf_data related properties
extern NSString * const SF_MSG_TITLE;
extern NSString * const SF_PLAN_STRATEGY_ID;
extern NSString * const SF_CHANNEL_CATEGORY;
extern NSString * const SF_AUDIENCE_ID;
extern NSString * const SF_CHANNEL_ID;
extern NSString * const SF_LINK_URL;
extern NSString * const SF_PLAN_TYPE;
extern NSString * const SF_CHANNEL_SERVICE_NAME;
extern NSString * const SF_MSG_ID;
extern NSString * const SF_PLAN_ID;
extern NSString * const SF_STRATEGY_UNIT_ID;
extern NSString * const SF_ENTER_PLAN_TIME;
extern NSString * const SF_MSG_CONTENT;
