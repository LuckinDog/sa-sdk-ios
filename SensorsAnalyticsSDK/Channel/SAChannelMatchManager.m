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
#import "SAAlertController.h"
#import "SAIdentifier.h"
#import "SALog.h"
#import "SAURLUtils.h"

#ifdef SENSORS_ANALYTICS_DISABLE_UIWEBVIEW
#import <WebKit/WebKit.h>
#endif

@interface SAChannelMatchManager ()

@property (nonatomic, assign) BOOL isValidAppInstall;
@property (nonatomic, assign) BOOL appInstalled;

@property (nonatomic, copy) NSString *userAgent;
@property (nonatomic, copy) NSURL *url;

#ifdef SENSORS_ANALYTICS_DISABLE_UIWEBVIEW
@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, strong) dispatch_group_t loadUAGroup;
#endif

@end

NSString *kChannelDebugFlagKey = @"sensorsdata_channel_debug_flag";

@implementation SAChannelMatchManager

+ (instancetype)sharedInstance {
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
    NSNumber *flag = [[NSUserDefaults standardUserDefaults] objectForKey:kChannelDebugFlagKey];
    return (flag != nil);
}

- (BOOL)isValidAppInstall {
    NSNumber *flag = [[NSUserDefaults standardUserDefaults] objectForKey:kChannelDebugFlagKey];
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
    [self trackAppInstallEvent:@"$ChannelDebugInstall" properties:nil];
}

- (void)trackAppInstallEvent:(NSString *)event properties:(NSDictionary *)propertyDict {
    // 追踪渠道是特殊功能，需要同时发送 track 和 profile_set_once
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    NSString *idfa = [SAIdentifier idfa];
    NSString *appInstallSource = idfa ? [NSString stringWithFormat:@"idfa=%@", idfa] : @"";
    [properties setValue:appInstallSource forKey:SA_EVENT_PROPERTY_APP_INSTALL_SOURCE];

    // 保存触发过 AppInstall 事件标志位
    [[NSUserDefaults standardUserDefaults] setValue:@(idfa != nil) forKey:kChannelDebugFlagKey];

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

#pragma mark - WhiteList Alert
- (BOOL)isValidURL:(NSURL *)url {
    NSDictionary *queryItems = [SAURLUtils queryItemsWithURL:url];
    NSString *monitorId = queryItems[@"monitor_id"];
    return [url.host isEqualToString:@"channeldebug"] && monitorId.length;
}

- (void)showAuthorizationAlert:(NSURL *)url {
    if (![self isValidURL:url]) {
        return;
    }
    NSString *title = @"即将开启「渠道白名单」模式";
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:title message:@"" preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"确认" style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
        if (!self.appInstalled || (self.isValidAppInstall && [SAIdentifier idfa])) {
            NSString *monitorId = [SAURLUtils queryItemsWithURL:url][@"monitor_id"];
            [self saveUserInfoIntoWhitList:monitorId];
        } else {
            [self showErrorMessageAlert];
        }
    }];

    [alertController addActionWithTitle:@"取消" style:SAAlertActionStyleCancel handler:nil];
    [alertController show];
}

- (void)saveUserInfoIntoWhitList:(NSString *)monitorId {
    // 请求逻辑地址修改
    NSURL *serverURL = SensorsAnalyticsSDK.sharedInstance.network.serverURL;
    if (serverURL.absoluteString.length <= 0) {
        return;
    }
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = serverURL.scheme;
    components.host = serverURL.host;
    components.port = serverURL.port;
    components.path = @"/api/sdk/channel_tool/url";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:components.URL];
    request.timeoutInterval = 60;
    [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"distinct_id"] = [[SensorsAnalyticsSDK sharedInstance] distinctId];
    params[@"monitor_id"] = monitorId;
    params[@"has_active"] = @(self.appInstalled);
    params[@"device_code"] = [SAIdentifier idfa];
    NSData *HTTPBody= [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
    request.HTTPBody = HTTPBody;

    if (!request) {
        return;
    }

    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    indicator.center = CGPointMake(window.center.x, window.center.y);
    [window addSubview:indicator];
    [indicator startAnimating];

    NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [indicator stopAnimating];
            [indicator removeFromSuperview];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            BOOL success = [dict[@"code"] boolValue];
            if (success) {
                [self showAppInstallAlert];
            } else {
                // TODO: 这里是否需要以服务端的错误信息为准？
                [self showRequestFailedAlert];
            }
        });
    }];
    [task resume];
}

- (void)showRequestFailedAlert {
    NSString *content = @"添加白名单请求失败，请联系神策技术支持人员排查问题";
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:@"" message:content preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"确认" style:SAAlertActionStyleCancel handler:nil];
    [alertController show];
}

- (void)showAppInstallAlert {
    NSString *title = @"成功开启「渠道白名单」模式";
    NSString *content = @"此模式下不需要卸载 App，点击下列 “激活” 按钮可以反复触发激活";
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:title message:content preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"激活" style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
        [self showAppInstallAlert];
        [self trackAppInstallEvent];
    }];
    [alertController show];
}

- (void)showErrorMessageAlert {
    NSString *title = @"检测到 “设备码为空”，可能原因如下，请排查：";
    NSString *content = @"1. 手机系统设置中选择禁用设备码；\n\n2. SDK 代码有误，请联系研发人员确认是否关闭“采集设备码”开关。\n\n 卸载并安装重新集成了修正的 SDK 的 App，再进行联调测试。";
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:title message:content preferredStyle:SAAlertControllerStyleAlert];
    [alertController show];

}

- (UIWindow *)currentAlertWindow {
    if (!NSClassFromString(@"UIAlertController")) {
        return [UIApplication sharedApplication].keyWindow;
    }
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000)
    if (@available(iOS 13.0, *)) {
        __block UIWindowScene *scene = nil;
        [[UIApplication sharedApplication].connectedScenes.allObjects enumerateObjectsUsingBlock:^(UIScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UIWindowScene class]]) {
                scene = (UIWindowScene *)obj;
                *stop = YES;
            }
        }];
        if (scene) {
            return [[UIWindow alloc] initWithWindowScene:scene];
        }
    }
#endif
    return [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

@end
