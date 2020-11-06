//
// SARemoteConfigCheckProcess.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/11/1.
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

#import "SARemoteConfigCheckProcess.h"
#import "SAConstants+Private.h"
#import "SAJSONUtil.h"
#import "SAURLUtils.h"
#import "SAAlertController.h"
#import "SACommonUtility.h"

@interface SARemoteConfigCheckProcess ()

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@end

@implementation SARemoteConfigCheckProcess

#pragma mark – Life Cycle

- (instancetype)initWithRemoteConfigProcessOptions:(SARemoteConfigProcessOptions *)options model:(SARemoteConfigModel *)model {
    self = [super initWithRemoteConfigProcessOptions:options];
    if (self) {
        self.model = model;
    }
    return self;
}

#pragma mark – Protocol

- (void)remoteConfigProcessHandleRemoteConfigURL:(NSURL *)url {
    NSDictionary *components = [SAURLUtils queryItemsWithURL:url];
    if (!components) {
        return;
    }
    
    NSString *project = components[@"project"] ?: @"default";
    NSString *appID = components[@"app_id"];
    NSString *os = components[@"os"];
    NSString *lastestVersion = components[@"nv"];
    
    NSString *currentProject = self.project ?: @"default";
    NSString *currentAppID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *currentOS = @"iOS";
    
    BOOL isCheckPassed = NO;
    NSString *message = nil;
    if (![currentProject isEqualToString:project]) {
        message = @"App 集成的项目与二维码对应的项目不同，无法进行调试";
    } else if (![currentAppID isEqualToString:appID]) {
        message = @"App 与二维码对应的 App 不同，无法进行调试";
    } else if (![currentOS isEqualToString:os]) {
        message = @"App 与二维码对应的操作系统不同，无法进行调试";
    } else if (!lastestVersion) {
        message = @"二维码信息校验失败，请检查采集控制是否配置正确";
    } else {
        isCheckPassed = YES;
        message = @"开始获取采集控制信息";
    }
    
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:@"提示" message:message preferredStyle:SAAlertControllerStyleAlert];
    if (isCheckPassed) {
        [alertController addActionWithTitle:@"取消" style:SAAlertActionStyleCancel handler:nil];
        [alertController addActionWithTitle:@"继续" style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
            [self requestRemoteConfigWithLastestVersion:lastestVersion];
        }];
    } else {
        [alertController addActionWithTitle:@"确定" style:SAAlertActionStyleDefault handler:nil];
    }
    [alertController show];
}

#pragma mark - Private

#pragma mark Request

- (void)requestRemoteConfigWithLastestVersion:(NSString *)lastestVersion {
    SensorsAnalyticsNetworkType networkType = [SACommonUtility currentNetworkType];
    if (networkType == SensorsAnalyticsNetworkTypeNONE) {
        [self showNetworkErrorAlert];
        return;
    }
    
    [self showIndicator];
    
    __weak typeof(self) weakSelf = self;
    [self requestRemoteConfigWithForceUpdate:YES completion:^(BOOL success, NSDictionary<NSString *,id> * _Nullable config) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf hideIndicator];
        
        if (success && config) {
            // 远程配置
            NSDictionary<NSString *, id> *remoteConfig = [strongSelf extractRemoteConfig:config];
            [strongSelf handleRemoteConfig:remoteConfig withLastestVersion:lastestVersion];
            
            // 加密
            if (strongSelf.options.configOptions.enableEncrypt) {
                NSDictionary<NSString *, id> *encryptConfig = [strongSelf extractEncryptConfig:config];
                strongSelf.options.handleEncryptBlock(encryptConfig);
            }
        } else {
            SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:@"提示" message:@"远程配置获取失败，请稍后再试" preferredStyle:SAAlertControllerStyleAlert];
            [alertController addActionWithTitle:@"确定" style:SAAlertActionStyleDefault handler:nil];
            [alertController show];
        }
    }];
}

- (void)showNetworkErrorAlert {
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:@"提示" message:@"网络连接失败，请检查设备网络" preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"确定" style:SAAlertActionStyleDefault handler:nil];
    [alertController show];
}

- (void)handleRemoteConfig:(NSDictionary<NSString *, id> *)remoteConfig withLastestVersion:(NSString *)lastestVersion {
    NSMutableDictionary<NSString *, id> *eventMDic = [NSMutableDictionary dictionaryWithDictionary:remoteConfig];
    eventMDic[@"debug"] = @YES;
    [self trackAppRemoteConfigChanged:eventMDic];
    
    if ([self checkRemoteConfig:remoteConfig withLastestVersion:lastestVersion]) {
        NSMutableDictionary<NSString *, id> *enableMDic = [NSMutableDictionary dictionaryWithDictionary:remoteConfig];
        enableMDic[@"localLibVersion"] = self.options.currentLibVersion;
        [self enableRemoteConfigWithDictionary:enableMDic];
    }
}

- (BOOL)checkRemoteConfig:(NSDictionary<NSString *, id> *)remoteConfig withLastestVersion:(NSString *)lastestVersion {
    NSString *title = @"提示";
    NSString *message = @"远程配置校验通过";
    BOOL isCheckPassed = YES;
    
    NSString *currentLastestVersion = [remoteConfig valueForKeyPath:@"configs.nv"];
    if (![lastestVersion isEqualToString:currentLastestVersion]) {
        title = @"信息版本不一致";
        message = [NSString stringWithFormat:@"获取到采集控制信息的版本：%@，二维码信息的版本：%@，请稍后重新扫描二维码", currentLastestVersion, lastestVersion];
        isCheckPassed = NO;
    }
    
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:@"提示" message:message preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"确定" style:SAAlertActionStyleDefault handler:nil];
    [alertController show];
    
    return isCheckPassed;
}

#pragma mark UI

- (void)showIndicator {
    _window = [self alertWindow];
    _window.windowLevel = UIWindowLevelAlert + 1;
    UIViewController *controller = [[SAAlertController alloc] init];
    _window.rootViewController = controller;
    _window.hidden = NO;
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _indicator.center = CGPointMake(_window.center.x, _window.center.y);
    [_window.rootViewController.view addSubview:_indicator];
    [_indicator startAnimating];
}

- (void)hideIndicator {
    [_indicator stopAnimating];
    _indicator = nil;
    _window = nil;
}

- (UIWindow *)alertWindow {
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
