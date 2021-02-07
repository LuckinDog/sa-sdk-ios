//
// SAApplicationDelegateProxy.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/7.
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

#import "SAApplicationDelegateProxy.h"
#import "SAClassHelper.h"
#import "NSObject+DelegateProxy.h"
#import "UIApplication+PushClick.h"
#import "SensorsAnalyticsSDK.h"
#import "SAAppPushConstants.h"
#import "SALog.h"
#import "SANotificationUtil.h"
#import <objc/message.h>

@implementation SAApplicationDelegateProxy

+ (void)invokeWithTarget:(NSObject *)target selector:(SEL)selector application:(UIApplication *)application userInfo:(NSDictionary *)userInfo completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    Class originalClass = NSClassFromString(target.sensorsdata_className) ?: target.superclass;
    struct objc_super targetSuper = {
        .receiver = target,
        .super_class = originalClass
    };
    // 消息转发给原始类
    void (*func)(struct objc_super *, SEL, id, id, id) = (void *)&objc_msgSendSuper;
    func(&targetSuper, selector, application, userInfo, completionHandler);
    
    // 当 target 和 delegate 不相等时为消息转发, 此时无需重复采集事件
    if (target != application.delegate) {
        return;
    }
    //track notification
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        SALogInfo(@"iOS version >= 10.0, callback for %@ was ignored.", @"application:didReceiveRemoteNotification:fetchCompletionHandler:");
        return;
    }
    
    if (application.applicationState != UIApplicationStateInactive) {
        return;
    }
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[SA_EVENT_PROPERTY_NOTIFICATION_CHANNEL] = SA_EVENT_PROPERTY_NOTIFICATION_CHANNEL_APPLE;
    
    if (userInfo) {
        [properties addEntriesFromDictionary:[SANotificationUtil propertiesFromUserInfo:userInfo]];
    }
    
    properties[SA_EVENT_PROPERTY_NOTIFICATION_TITLE] = userInfo[SA_PUSH_APPLE_USER_INFO_KEY_APS][SA_PUSH_APPLE_USER_INFO_KEY_ALERT][SA_PUSH_APPLE_USER_INFO_KEY_TITLE];
    properties[SA_EVENT_PROPERTY_NOTIFICATION_CONTENT] = userInfo[SA_PUSH_APPLE_USER_INFO_KEY_APS][SA_PUSH_APPLE_USER_INFO_KEY_ALERT][SA_PUSH_APPLE_USER_INFO_KEY_BODY];
    
    [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_NOTIFICATION_CLICK withProperties:properties];
}

+ (void)invokeWithTarget:(NSObject *)target selector:(SEL)selector application:(UIApplication *)application localNotification:(UILocalNotification *)notification  {
    Class originalClass = NSClassFromString(target.sensorsdata_className) ?: target.superclass;
    struct objc_super targetSuper = {
        .receiver = target,
        .super_class = originalClass
    };
    // 消息转发给原始类
    void (*func)(struct objc_super *, SEL, id, id) = (void *)&objc_msgSendSuper;
    func(&targetSuper, selector, application, notification);
    
    // 当 target 和 delegate 不相等时为消息转发, 此时无需重复采集事件
    if (target != application.delegate) {
        return;
    }
    //track notification
    BOOL isValidPushClick = NO;
    if (application.applicationState == UIApplicationStateInactive) {
        isValidPushClick = YES;
    } else if (application.sensorsdata_launchOptions[UIApplicationLaunchOptionsLocalNotificationKey]) {
        isValidPushClick = YES;
        application.sensorsdata_launchOptions = nil;
    }
    
    if (!isValidPushClick) {
        SALogInfo(@"Invalid app push callback, AppPushClick was ignored.");
        return;
    }
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[SA_EVENT_PROPERTY_NOTIFICATION_CONTENT] = notification.alertBody;
    properties[SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME] = SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME_LOCAL;
    
    if (@available(iOS 8.2, *)) {
        properties[SA_EVENT_PROPERTY_NOTIFICATION_TITLE] = notification.alertTitle;
    }
    
    [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_NOTIFICATION_CLICK withProperties:properties];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    SEL selector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
    [SAApplicationDelegateProxy invokeWithTarget:self selector:selector application:application userInfo:userInfo completionHandler:completionHandler];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    SEL selector = @selector(application:didReceiveLocalNotification:);
    [SAApplicationDelegateProxy invokeWithTarget:self selector:selector application:application localNotification:notification];
}

@end
