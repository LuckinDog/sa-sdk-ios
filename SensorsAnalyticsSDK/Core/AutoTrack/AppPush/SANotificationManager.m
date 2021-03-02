//
// SANotificationManager.m
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

#import "SANotificationManager.h"
#import "SAApplicationDelegateProxy.h"
#import "SASwizzle.h"
#import "SALog.h"
#import "UIApplication+PushClick.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import "SAUNUserNotificationCenterDelegateProxy.h"
#endif

@implementation SANotificationManager

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    if (enable) {
        [self proxyNotifications];
    }
}

- (void)setLaunchOptions:(NSDictionary *)launchOptions {
    [UIApplication sharedApplication].sensorsdata_launchOptions = launchOptions;
}

- (void)proxyNotifications {
    //UIApplicationDelegate proxy
    [SAApplicationDelegateProxy proxyDelegate:[UIApplication sharedApplication].delegate selectors:@[@"application:didReceiveLocalNotification:", @"application:didReceiveRemoteNotification:fetchCompletionHandler:"]];
    
    //UNUserNotificationCenterDelegate proxy
    if (@available(iOS 10.0, *)) {
        if ([UNUserNotificationCenter currentNotificationCenter].delegate) {
            [SAUNUserNotificationCenterDelegateProxy proxyDelegate:[UNUserNotificationCenter currentNotificationCenter].delegate selectors:@[@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"]];
        }
        NSError *error = NULL;
        [UNUserNotificationCenter sa_swizzleMethod:@selector(setDelegate:) withMethod:@selector(sensorsdata_setDelegate:) error:&error];
        if (error) {
            SALogError(@"proxy notification delegate error: %@", error);
        }
    }
}

@end
