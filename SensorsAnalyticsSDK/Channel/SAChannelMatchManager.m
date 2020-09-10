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
#import "SAAlertController.h"
#import "SAURLUtils.h"
#import "SAReachability.h"

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

- (BOOL)isAppInstall {
    NSNumber *appInstalled = [[NSUserDefaults standardUserDefaults] objectForKey:kChannelDebugFlagKey];
    return (appInstalled != nil);
}

- (BOOL)isIDFAEmptyOfAppInstall {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kChannelDebugFlagKey];
}

#pragma mark - AppInstall
- (void)trackInstallation:(NSString *)event properties:(NSDictionary *)propertyDict disableCallback:(BOOL)disableCallback {

    NSString *userDefaultsKey = disableCallback ? SA_HAS_TRACK_INSTALLATION_DISABLE_CALLBACK : SA_HAS_TRACK_INSTALLATION;
    BOOL hasTrackInstallation = [[NSUserDefaults standardUserDefaults] boolForKey:userDefaultsKey];
    if (hasTrackInstallation) {
        return;
    }
    // 渠道联调诊断 - 激活事件中 IDFA 内容是否为空
    BOOL isNotEmpty = [SAIdentifier idfa] != nil;
    [[NSUserDefaults standardUserDefaults] setValue:@(isNotEmpty) forKey:kChannelDebugFlagKey];

    // 激活事件 - 根据 disableCallback 记录是否触发过激活事件
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:userDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    [properties addEntriesFromDictionary:propertyDict];
    if (disableCallback) {
        [properties setValue:@YES forKey:SA_EVENT_PROPERTY_APP_INSTALL_DISABLE_CALLBACK];
    }
    [self trackAppInstallEvent:event properties:properties];
}

- (void)trackChannelDebugInstallEvent {
    [self trackAppInstallEvent:@"$ChannelDebugInstall" properties:nil];
}

- (void)trackAppInstallEvent:(NSString *)event properties:(NSDictionary *)propertyDict {
    // 追踪渠道是特殊功能，需要同时发送 track 和 profile_set_once
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    NSString *idfa = [SAIdentifier idfa];
    NSString *appInstallSource = idfa ? [NSString stringWithFormat:@"idfa=%@", idfa] : @"";
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
        [[SensorsAnalyticsSDK sharedInstance] track:event withProperties:newProperties withTrackType:SensorsAnalyticsTrackTypeAuto];

        // 再发送 profile_set_once
        [newProperties setValue:[NSDate date] forKey:SA_EVENT_PROPERTY_APP_INSTALL_FIRST_VISIT_TIME];
        if (self.enableMultipleChannelMatch) {
            [[SensorsAnalyticsSDK sharedInstance] set:newProperties];
        } else {
            [[SensorsAnalyticsSDK sharedInstance] setOnce:newProperties];
        }
        [[SensorsAnalyticsSDK sharedInstance] flush];
    };

    if (userAgent.length == 0) {
        [[SensorsAnalyticsSDK sharedInstance] loadUserAgentWithCompletion:^(NSString *ua) {
            userAgent = ua;
            trackInstallationBlock();
        }];
    } else {
        trackInstallationBlock();
    }
}

#pragma mark - Alert
- (BOOL)isValidURL:(NSURL *)url {
    NSDictionary *queryItems = [SAURLUtils queryItemsWithURL:url];
    NSString *monitorId = queryItems[@"monitor_id"];
    return [url.host isEqualToString:@"channeldebug"] && monitorId.length;
}

- (void)showAuthorizationAlert:(NSURL *)url {
    if (![self isValidURL:url]) {
        return;
    }

    SANetwork *network = [SensorsAnalyticsSDK sharedInstance].network;
    if (!network.serverURL.absoluteString.length) {
        [self showErrorMessage:@"数据接收地址错误，无法使用联调诊断工具"];
        return;
    }
    NSString *project = [SAURLUtils queryItemsWithURLString:url.absoluteString][@"project"] ?: @"default";
    BOOL isEqualProject = [network.project isEqualToString:project];
    if (!isEqualProject) {
        [self showErrorMessage:@"App 集成的项目与电脑浏览器打开的项目不同，无法使用联调诊断工具"];
        return;
    }

    SAReachability *reachability = [SAReachability reachabilityForInternetConnection];
    SANetworkStatus status = [reachability currentReachabilityStatus];
    if (status == SANotReachable) {
        [self showErrorMessage:@"当前网络状况不可用，请检查网络状况后重试"];
        return;
    }

    NSString *title = @"即将开启「渠道管理白名单」模式";
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:title message:@"" preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"确认" style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
        if (![self isAppInstall] || ([self isIDFAEmptyOfAppInstall] && [SAIdentifier idfa])) {
            NSDictionary *qureyItems = [SAURLUtils queryItemsWithURL:url];
            [self uploadUserInfoIntoWhiteList:qureyItems];
        } else {
            [self showChannelDebugErrorMessage];
        }
    }];
    [alertController addActionWithTitle:@"取消" style:SAAlertActionStyleCancel handler:nil];
    [alertController show];
}

- (void)uploadUserInfoIntoWhiteList:(NSDictionary *)qureyItems {
    // 请求逻辑地址修改
    NSURL *serverURL = SensorsAnalyticsSDK.sharedInstance.network.serverURL;
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
    params[@"has_active"] = @([self isAppInstall]);
    params[@"device_code"] = [SAIdentifier idfa];
    [params addEntriesFromDictionary:qureyItems];
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];

    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    indicator.center = CGPointMake(window.center.x, window.center.y);
    [window addSubview:indicator];
    [indicator startAnimating];

    NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
        NSDictionary *dict = [NSDictionary dictionary];
        if (data) {
            dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        }
        BOOL code = [dict[@"code"] integerValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            [indicator stopAnimating];
            // 只有当 code 为 1 时表示请求成功
            if (code == 1) {
                [self showChannelDebugInstall];
            } else {
                NSString *message = dict[@"message"] ?: @"添加白名单请求失败，请联系神策技术支持人员排查问题";
                [self showErrorMessage:message];
            }
        });
    }];
    [task resume];
}

- (void)showChannelDebugInstall {
    NSString *title = @"成功开启「渠道管理白名单」模式";
    NSString *content = @"此模式下不需要卸载 App，点击下列 “激活” 按钮可以反复触发激活";
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:title message:content preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"激活" style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
        [self showChannelDebugInstall];
        [self trackChannelDebugInstallEvent];
    }];
    [alertController show];
}

- (void)showChannelDebugErrorMessage {
    NSString *title = @"检测到 “设备码为空”，可能原因如下，请排查：";
    NSString *content = @"1. 手机系统设置中选择禁用设备码；\n\n2. SDK 代码有误，请联系研发人员确认是否关闭“采集设备码”开关。\n\n 卸载并安装重新集成了修正的 SDK 的 App，再进行联调测试。";
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:title message:content preferredStyle:SAAlertControllerStyleAlert];
    [alertController show];
}

- (void)showErrorMessage:(NSString *)errorMessage {
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:@"提示" message:errorMessage preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"确认" style:SAAlertActionStyleCancel handler:nil];
    [alertController show];
}

@end
