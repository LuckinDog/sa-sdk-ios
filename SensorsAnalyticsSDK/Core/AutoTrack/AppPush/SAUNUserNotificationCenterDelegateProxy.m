//
// SAUNUserNotificationCenterDelegateProxy.m
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

#import "SAUNUserNotificationCenterDelegateProxy.h"
#import "SAClassHelper.h"
#import "NSObject+DelegateProxy.h"
#import "SAAppPushConstants.h"
#import "SensorsAnalyticsSDK.h"
#import "SALog.h"
#import "SANotificationUtil.h"
#import <objc/message.h>

@implementation SAUNUserNotificationCenterDelegateProxy

+ (void)invokeWithTarget:(NSObject *)target selector:(SEL)selector notificationCenter:(UNUserNotificationCenter *)center notificationResponse:(UNNotificationResponse *)response completionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(10.0)){
    Class originalClass = NSClassFromString(target.sensorsdata_className) ?: target.superclass;
    struct objc_super targetSuper = {
        .receiver = target,
        .super_class = originalClass
    };
    // 消息转发给原始类
    void (*func)(struct objc_super *, SEL, id, id, id) = (void *)&objc_msgSendSuper;
    func(&targetSuper, selector, center, response, completionHandler);
    
    // 当 target 和 delegate 不相等时为消息转发, 此时无需重复采集事件
    if (target != center.delegate) {
        return;
    }
    //track notification
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    UNNotificationRequest *request = response.notification.request;
    BOOL isRemoteNotification = [request.trigger isKindOfClass:[UNPushNotificationTrigger class]];
    if (isRemoteNotification) {
        properties[SA_EVENT_PROPERTY_NOTIFICATION_CHANNEL] = SA_EVENT_PROPERTY_NOTIFICATION_CHANNEL_APPLE;
    } else {
        properties[SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME] = SA_EVENT_PROPERTY_NOTIFICATION_SERVICE_NAME_LOCAL;
    }
    
    properties[SA_EVENT_PROPERTY_NOTIFICATION_TITLE] = request.content.title;
    properties[SA_EVENT_PROPERTY_NOTIFICATION_CONTENT] = request.content.body;
    
    NSDictionary *userInfo = request.content.userInfo;
    if (userInfo) {
        [properties addEntriesFromDictionary:[SANotificationUtil propertiesFromUserInfo:userInfo]];
    }
    
    [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_NOTIFICATION_CLICK withProperties:properties];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(10.0)){
    SEL selector = @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
    [SAUNUserNotificationCenterDelegateProxy invokeWithTarget:self selector:selector notificationCenter:center notificationResponse:response completionHandler:completionHandler];
}

@end
