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
#import "SACommonUtility.h"
#import "SALog.h"

#ifdef SENSORS_ANALYTICS_DISABLE_UIWEBVIEW
#import <WebKit/WebKit.h>
#endif

#import "SAChannelWhiteListManager.h"

@interface SAChannelMatchManager ()

@property (nonatomic, assign) BOOL deviceIdEmpty;
@property (nonatomic, assign) BOOL appInstalled;

@property (nonatomic, copy) NSString *userAgent;

#ifdef SENSORS_ANALYTICS_DISABLE_UIWEBVIEW
@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, strong) dispatch_group_t loadUAGroup;
#endif

@property (nonatomic, assign) BOOL disableCallback;

@end

@implementation SAChannelMatchManager

+ (instancetype)manager {
    static dispatch_once_t onceToken;
    static SAChannelMatchManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[SAChannelMatchManager alloc] init];
    });
    return manager;
}

- (void)updateUserAgent:(NSString *)userAgent {
    self.userAgent = userAgent;
}

- (BOOL)appInstalled {
    NSNumber *flag = [[NSUserDefaults standardUserDefaults] objectForKey:@"channel_debbug_flag"];
    return (flag != nil);
}

- (BOOL)deviceIdEmpty {
    NSNumber *flag = [[NSUserDefaults standardUserDefaults] objectForKey:@"channel_debbug_flag"];
    return flag.boolValue;
}

- (void)trackInstallation:(NSString *)event properties:(NSDictionary *)propertyDict disableCallback:(BOOL)disableCallback {

    NSString *userDefaultsKey = disableCallback ? SA_HAS_TRACK_INSTALLATION_DISABLE_CALLBACK : SA_HAS_TRACK_INSTALLATION;
    BOOL hasTrackInstallation = [[NSUserDefaults standardUserDefaults] boolForKey:userDefaultsKey];
    if (hasTrackInstallation) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:userDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    [properties addEntriesFromDictionary:propertyDict];
    if (disableCallback) {
        [properties setValue:@YES forKey:SA_EVENT_PROPERTY_APP_INSTALL_DISABLE_CALLBACK];
    }
    [self trackAppInstallEvent:event properties:properties];
}

- (void)trackAppInstallEvent {
    [self trackAppInstallEvent:@"AppInstall" properties:nil];
}

- (void)trackAppInstallEvent:(NSString *)event properties:(NSDictionary *)propertyDict {
    // 追踪渠道是特殊功能，需要同时发送 track 和 profile_set_once
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    NSString *idfa = [SAIdentifier idfa];
    NSString *appInstallSource = idfa ? [NSString stringWithFormat:@"idfa=%@", idfa] : @"";

    // 保存触发过 AppInstall 事件标志位
    [[NSUserDefaults standardUserDefaults] setValue:@(idfa != nil) forKey:@"channel_debbug_flag"];
    [properties setValue:appInstallSource forKey:SA_EVENT_PROPERTY_APP_INSTALL_SOURCE];

    __block NSString *userAgent = [propertyDict objectForKey:SA_EVENT_PROPERTY_APP_USER_AGENT];
    dispatch_block_t trackInstallationBlock = ^{
        if (userAgent) {
            [properties setValue:userAgent forKey:SA_EVENT_PROPERTY_APP_USER_AGENT];
        }

        NSMutableDictionary *newProperties = [properties mutableCopy];
        if ([SAValidator isValidDictionary:propertyDict]) {
            [newProperties addEntriesFromDictionary:propertyDict];
        }
        // 先发送 track
        [[SensorsAnalyticsSDK sharedInstance] track:event withProperties:[newProperties copy] withTrackType:SensorsAnalyticsTrackTypeAuto];

        // 再发送 profile_set_once
        [newProperties setValue:[NSDate date] forKey:SA_EVENT_PROPERTY_APP_INSTALL_FIRST_VISIT_TIME];
        if (self.configOptions.enableMultipleChannelMatch) {
            [[SensorsAnalyticsSDK sharedInstance] set:newProperties];
        } else {
            [[SensorsAnalyticsSDK sharedInstance] setOnce:newProperties];
        }
        [[SensorsAnalyticsSDK sharedInstance] flush];
    };

    if (userAgent.length == 0) {
        [self loadUserAgentWithCompletion:^(NSString *ua) {
            userAgent = ua;
            trackInstallationBlock();
        }];
    } else {
        trackInstallationBlock();
    }
}

- (void)loadUserAgentWithCompletion:(void (^)(NSString *))completion {
    if (self.userAgent) {
        return completion(self.userAgent);
    }
#ifdef SENSORS_ANALYTICS_DISABLE_UIWEBVIEW
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.wkWebView) {
            dispatch_group_notify(self.loadUAGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                completion(self.userAgent);
            });
        } else {
            self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero];
            self.loadUAGroup = dispatch_group_create();
            dispatch_group_enter(self.loadUAGroup);

            __weak typeof(self) weakSelf = self;
            [self.wkWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable response, NSError *_Nullable error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;

                if (error || !response) {
                    SALogError(@"WKWebView evaluateJavaScript load UA error:%@", error);
                    completion(nil);
                } else {
                    strongSelf.userAgent = response;
                    completion(strongSelf.userAgent);
                }

                // 通过 wkWebView 控制 dispatch_group_leave 的次数
                if (strongSelf.wkWebView) {
                    dispatch_group_leave(strongSelf.loadUAGroup);
                }

                strongSelf.wkWebView = nil;
            }];
        }
    });
#else
    [SACommonUtility performBlockOnMainThread:^{
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        self.userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        completion(self.userAgent);
    }];
#endif
}

@end
