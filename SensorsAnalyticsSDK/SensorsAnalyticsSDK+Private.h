//
//  SensorsAnalyticsSDK_priv.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/8/9.
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

#ifndef SensorsAnalyticsSDK_Private_h
#define SensorsAnalyticsSDK_Private_h
#import "SensorsAnalyticsSDK.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "SANetwork.h"
#import "SADataEncryptBuilder.h"


@interface SensorsAnalyticsSDK(Private)

#pragma mark - method
- (void)autoTrackViewScreen:(UIViewController *)viewController;

/**
触发 signup 事件

@param propertiesDict event 的属性
*/
- (void)trackSignupEvent:(NSDictionary *)propertiesDict;

/**
触发自定义事件

@param event 事件名
@param propertiesDict 事件的属性
*/
- (void)trackCustomEvent:(NSString *)event properties:(NSDictionary *)propertiesDict;

/**
触发全埋点事件

@param event 事件名
@param properties 事件的属性
@param isAuto 是否为自动触发
*/
- (void)trackAutoEvent:(NSString *)event properties:(NSDictionary *)properties isAuto:(BOOL)isAuto;

/**
自动触发全埋点事件

@param event 事件名
@param properties 事件的属性
*/
- (void)trackAutoEvent:(NSString *)event properties:(NSDictionary *)properties;

- (void)showDebugModeWarning:(NSString *)message withNoMoreButton:(BOOL)showNoMore;


/**
 根据 viewController 判断，是否采集事件

 @param controller 事件采集时的控制器
 @param type 事件类型
 @return 是否采集
 */
- (BOOL)shouldTrackViewController:(UIViewController *)controller ofType:(SensorsAnalyticsAutoTrackEventType)type;

/**
向 WKWebView 注入 Message Handler

@param webView 需要注入的 wkwebView
*/
- (void)addScriptMessageHandlerWithWebView:(WKWebView *)webView;

#pragma mark - property
@property (nonatomic, strong, readonly) SAConfigOptions *configOptions;

@property (nonatomic, strong, readonly) SANetwork *network;

@property (nonatomic, strong, readonly) SADataEncryptBuilder *encryptBuilder;

@property (nonatomic, weak) UIViewController *previousTrackViewController;

@end



/**
 SAConfigOptions 实现
 私有 property
 */
@interface SAConfigOptions()

/// 数据接收地址 serverURL
@property(nonatomic, copy) NSString *serverURL;

/// App 启动的 launchOptions
@property(nonatomic, copy) NSDictionary *launchOptions;

@end

#endif /* SensorsAnalyticsSDK_priv_h */
