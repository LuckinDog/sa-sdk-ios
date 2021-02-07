//
// SAAppPushConstants.m
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

#import "SAAppPushConstants.h"

//AppPush Notification related
NSString * const SA_EVENT_NAME_APP_NOTIFICATION_CLICK = @"$AppPushClick";
NSString * const SA_EVENT_PROPERTY_NOTIFICATION_TITLE = @"$app_push_msg_title";
NSString * const SA_EVENT_PROPERTY_NOTIFICATION_CONTENT = @"$app_push_msg_content";
NSString * const SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME = @"$app_push_service_name";
NSString * const SA_EVENT_PROPERTY_NOTIFICATION_CHANNEL = @"$app_push_channel";
NSString * const SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME_LOCAL = @"Local";
NSString * const SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME_JPUSH = @"JPush";
NSString * const SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME_GETUI = @"GeTui";
NSString * const SA_EVENT_PROPERTY_NOTIFICATION_CHANNEL_APPLE = @"Apple";

//identifier for third part push service
NSString * const SA_PUSH_SERVICE_KEY_JPUSH = @"_j_business";
NSString * const SA_PUSH_SERVICE_KEY_GETUI = @"_ge_";
NSString * const SA_PUSH_SERVICE_KEY_SF = @"sf_data";

//APNS related key
NSString * const SA_PUSH_APPLE_USER_INFO_KEY_APS = @"aps";
NSString * const SA_PUSH_APPLE_USER_INFO_KEY_ALERT = @"alert";
NSString * const SA_PUSH_APPLE_USER_INFO_KEY_TITLE = @"title";
NSString * const SA_PUSH_APPLE_USER_INFO_KEY_BODY = @"body";

//sf_data related properties
NSString * const SF_MSG_TITLE = @"$sf_msg_title";
NSString * const SF_PLAN_STRATEGY_ID = @"$sf_plan_strategy_id";
NSString * const SF_CHANNEL_CATEGORY = @"$sf_channel_category";
NSString * const SF_AUDIENCE_ID = @"$sf_audience_id";
NSString * const SF_CHANNEL_ID = @"$sf_channel_id";
NSString * const SF_LINK_URL = @"$sf_link_url";
NSString * const SF_PLAN_TYPE = @"$sf_plan_type";
NSString * const SF_CHANNEL_SERVICE_NAME = @"$sf_channel_service_name";
NSString * const SF_MSG_ID = @"$sf_msg_id";
NSString * const SF_PLAN_ID = @"$sf_plan_id";
NSString * const SF_STRATEGY_UNIT_ID = @"$sf_strategy_unit_id";
NSString * const SF_ENTER_PLAN_TIME = @"$sf_enter_plan_time";
NSString * const SF_MSG_CONTENT = @"$sf_msg_content";
