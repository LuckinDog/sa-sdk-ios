//
//  SAConstants+Private.h
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2019/4/8.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import "SAConstants.h"

#pragma mark - Track Timer
extern NSString  * const kSAEventIdSuffix;

#pragma mark--evnet
extern NSString * const kSAEventTime;
extern NSString * const kSAEventTrackId;
extern NSString * const kSAEventName;
extern NSString * const kSAEventDistinctId;
extern NSString * const kSAEventProperties;
extern NSString * const kSAEventType;
extern NSString * const kSAEventLib;
extern NSString * const kSAEventProject;
extern NSString * const kSAEventToken;
extern NSString * const kSAEventHybridH5;
extern NSString * const kSAEventLoginId;
extern NSString * const kSAEventAnonymousId;

#pragma mark - Item
extern NSString * const SA_EVENT_ITEM_TYPE;
extern NSString * const SA_EVENT_ITEM_ID;
extern NSString * const SA_EVENT_ITEM_SET;
extern NSString * const SA_EVENT_ITEM_DELETE;

#pragma mark--evnet nanme

// App 启动或激活
extern NSString * const kSAEventNameAppStart;
// App 退出或进入后台
extern NSString * const kSAEventNameAppEnd;
// App 浏览页面
extern NSString * const kSAEventNameAppViewScreen;
// App 元素点击
extern NSString * const kSAEventNameAppClick;
// 自动追踪相关事件及属性
extern NSString * const kSAEventNameAppStartPassively;

extern NSString * const kSAEventNameSignUp;

extern NSString * const kSAEventNameAppCrashed;

extern NSString * const kSAEventNameAppRemoteConfigChanged;

// 激活事件
extern NSString * const kSAEventNameAppInstall;

#pragma mark--app install property
extern NSString * const SA_EVENT_PROPERTY_APP_INSTALL_SOURCE;
extern NSString * const SA_EVENT_PROPERTY_APP_INSTALL_DISABLE_CALLBACK;
extern NSString * const SA_EVENT_PROPERTY_APP_USER_AGENT;
extern NSString * const SA_EVENT_PROPERTY_APP_INSTALL_FIRST_VISIT_TIME;

#pragma mark--autoTrack property
// App 首次启动
extern NSString * const SA_EVENT_PROPERTY_APP_FIRST_START;
// App 是否从后台恢复
extern NSString * const SA_EVENT_PROPERTY_RESUME_FROM_BACKGROUND;
// App 浏览页面 Url
extern NSString * const SA_EVENT_PROPERTY_SCREEN_URL;
// App 浏览页面 Referrer Url
extern NSString * const SA_EVENT_PROPERTY_SCREEN_REFERRER_URL;
extern NSString * const SA_EVENT_PROPERTY_ELEMENT_ID;
extern NSString * const SA_EVENT_PROPERTY_SCREEN_NAME;
extern NSString * const SA_EVENT_PROPERTY_TITLE;
extern NSString * const SA_EVENT_PROPERTY_ELEMENT_POSITION;
extern NSString * const SA_EVENT_PROPERTY_ELEMENT_SELECTOR;
extern NSString * const SA_EVENT_PROPERTY_ELEMENT_PATH;
extern NSString * const SA_EVENT_PROPERTY_ELEMENT_CONTENT;
extern NSString * const SA_EVENT_PROPERTY_ELEMENT_TYPE;
extern NSString * const SA_EVENT_PROPERTY_CHANNEL_INFO;
extern NSString * const SA_EVENT_PROPERTY_CHANNEL_CALLBACK_EVENT;

extern NSString * const kSAEeventPropertyReferrerTitle;

// 远程控制配置信息
extern NSString * const SA_EVENT_PROPERTY_APP_REMOTE_CONFIG;

#pragma mark--common property
//可选参数
extern NSString * const kSAEventCommonOptionalPropertyProject;
extern NSString * const kSAEventCommonOptionalPropertyToken;
extern NSString * const kSAEventCommonOptionalPropertyTime;
extern long long const kSAEventCommonOptionalPropertyTimeInt;

#pragma mark--lib method
extern NSString * const kSALibMethodAuto;
extern NSString * const kSALibMethodCode;

#pragma mark--track
extern NSString * const kSAEventTypeTrack;
extern NSString * const kSAEventTypeSignup;

#pragma mark--profile
extern NSString * const SA_PROFILE_SET;
extern NSString * const SA_PROFILE_SET_ONCE;
extern NSString * const SA_PROFILE_UNSET;
extern NSString * const SA_PROFILE_DELETE;
extern NSString * const SA_PROFILE_APPEND;
extern NSString * const SA_PROFILE_INCREMENT;

#pragma mark--others
extern NSString * const SA_HAS_LAUNCHED_ONCE;
extern NSString * const SA_HAS_TRACK_INSTALLATION;
extern NSString * const SA_HAS_TRACK_INSTALLATION_DISABLE_CALLBACK;

#pragma mark - bridge name
extern NSString * const SA_SCRIPT_MESSAGE_HANDLER_NAME;

#pragma mark - reserved property list
NSSet* sensorsdata_reserved_properties(void);

#pragma mark - safe sync
BOOL sensorsdata_is_same_queue(dispatch_queue_t queue);

void sensorsdata_dispatch_safe_sync(dispatch_queue_t queue,DISPATCH_NOESCAPE dispatch_block_t block);

#pragma mark - Scheme Host
extern NSString * const kSASchemeHostRemoteConfig;

#pragma mark - SF related notifications
extern NSNotificationName const SA_TRACK_EVENT_NOTIFICATION;
extern NSNotificationName const SA_TRACK_LOGIN_NOTIFICATION;
extern NSNotificationName const SA_TRACK_LOGOUT_NOTIFICATION;
extern NSNotificationName const SA_TRACK_IDENTIFY_NOTIFICATION;
extern NSNotificationName const SA_TRACK_RESETANONYMOUSID_NOTIFICATION;
extern NSNotificationName const SA_TRACK_EVENT_H5_NOTIFICATION;

#pragma mark - ABTest related notifications
/// 注入打通 bridge
extern NSNotificationName const SA_H5_BRIDGE_NOTIFICATION;

/// H5 通过 postMessage 发送消息
extern NSNotificationName const SA_H5_MESSAGE_NOTIFICATION;

#pragma mark - SA notifications
extern NSNotificationName const SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION;

