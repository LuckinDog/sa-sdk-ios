//
// SARemoteConfigCheckOperator.m
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

#import "SARemoteConfigCheckOperator.h"
#import "SAConstants+Private.h"
#import "SAURLUtils.h"
#import "SAAlertController.h"
#import "SACommonUtility.h"
#import "SALog.h"

typedef void (^ SARemoteConfigCheckAlertHandler)(SAAlertAction *action);

@interface SARemoteConfigCheckAlertModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *defaultStyleTitle;
@property (nonatomic, copy) SARemoteConfigCheckAlertHandler defaultStyleHandler;
@property (nonatomic, copy) NSString *cancelStyleTitle;
@property (nonatomic, copy) SARemoteConfigCheckAlertHandler cancelStyleHandler;

@end

@implementation SARemoteConfigCheckAlertModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _title = @"提示";
        _message = nil;
        _defaultStyleTitle = @"确定";
        _defaultStyleHandler = nil;
        _cancelStyleTitle = nil;
        _cancelStyleHandler = nil;
    }
    return self;
}

@end

@interface SARemoteConfigCheckOperator ()

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@end

@implementation SARemoteConfigCheckOperator

#pragma mark - Life Cycle

- (instancetype)initWithRemoteConfigOptions:(SARemoteConfigOptions *)options remoteConfigModel:(SARemoteConfigModel *)model {
    self = [super initWithRemoteConfigOptions:options];
    if (self) {
        self.model = model;
    }
    return self;
}

#pragma mark - Protocol

- (void)handleRemoteConfigURL:(NSURL *)url {
    SALogDebug(@"【remote config】The input QR url is: %@", url);
    
    if ([SACommonUtility currentNetworkType] == SensorsAnalyticsNetworkTypeNONE) {
        [self showNetworkErrorAlert];
        return;
    }
    
    NSDictionary *components = [SAURLUtils queryItemsWithURL:url];
    if (!components) {
        SALogError(@"【remote config】The QR url format is invalid");
        return;
    }
    
    NSString *project = components[@"project"] ?: @"default";
    NSString *appID = components[@"app_id"];
    NSString *os = components[@"os"];
    NSString *lastestVersion = components[@"nv"];
    SALogDebug(@"【remote config】The input QR url project is %@, app_id is %@, os is %@", project, appID, os);
    
    NSString *currentProject = self.project ?: @"default";
    NSString *currentAppID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *currentOS = @"iOS";
    SALogDebug(@"【remote config】The current project is %@, app_id is %@, os is %@", currentProject, currentAppID, currentOS);
    
    BOOL isCheckPassed = NO;
    NSString *message = nil;
    if (![currentProject isEqualToString:project]) {
        message = @"App 集成的项目与二维码对应的项目不同，无法进行调试";
    } else if (![currentAppID isEqualToString:appID]) {
        message = @"当前 App 与二维码对应的 App 不同，无法进行调试";
    } else if (![currentOS isEqualToString:os]) {
        message = @"App 与二维码对应的操作系统不同，无法进行调试";
    } else if (!lastestVersion) {
        message = @"二维码信息校验失败，请检查采集控制是否配置正确";
    } else {
        isCheckPassed = YES;
        message = @"开始获取采集控制信息";
    }
    
    [self showURLCheckResultAlertWithMessage:message isCheckPassed:isCheckPassed lastestVersion:lastestVersion];
}

#pragma mark - Private

#pragma mark Alert

- (void)showNetworkErrorAlert {
    SARemoteConfigCheckAlertModel *model = [[SARemoteConfigCheckAlertModel alloc] init];
    model.message = @"网络连接失败，请检查设备网络";
    [self showAlertWithModel:model];
}

- (void)showURLCheckResultAlertWithMessage:(NSString *)message isCheckPassed:(BOOL)isCheckPassed lastestVersion:(NSString *)lastestVersion {
    SARemoteConfigCheckAlertModel *model = [[SARemoteConfigCheckAlertModel alloc] init];
    model.message = message;
    if (isCheckPassed) {
        model.defaultStyleTitle = @"继续";
        __weak typeof(self) weakSelf = self;
        model.defaultStyleHandler = ^(SAAlertAction *action) {
            __strong typeof(weakSelf) strongSelf = weakSelf;

            [strongSelf requestRemoteConfigWithLastestVersion:lastestVersion];
        };
        model.cancelStyleTitle = @"取消";
    }
    [self showAlertWithModel:model];
}

- (void)showRequestRemoteConfigFailedAlert {
    SARemoteConfigCheckAlertModel *model = [[SARemoteConfigCheckAlertModel alloc] init];
    model.message = @"远程配置获取失败，请稍后再试";
    [self showAlertWithModel:model];
}

- (void)showCheckRemoteConfigVersionAlertWithTitle:(NSString *)title message:(NSString *)message {
    SARemoteConfigCheckAlertModel *model = [[SARemoteConfigCheckAlertModel alloc] init];
    model.title = title;
    model.message = message;
    [self showAlertWithModel:model];
}

- (void)showAlertWithModel:(SARemoteConfigCheckAlertModel *)model {
    [SACommonUtility performBlockOnMainThread:^{
        SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:model.title message:model.message preferredStyle:SAAlertControllerStyleAlert];
        [alertController addActionWithTitle:model.defaultStyleTitle style:SAAlertActionStyleDefault handler:model.defaultStyleHandler];
        if (model.cancelStyleTitle) {
            [alertController addActionWithTitle:model.cancelStyleTitle style:SAAlertActionStyleCancel handler:model.cancelStyleHandler];
        }
        [alertController show];
    }];
}

#pragma mark Request

- (void)requestRemoteConfigWithLastestVersion:(NSString *)lastestVersion {
    [self showIndicator];
    
    __weak typeof(self) weakSelf = self;
    [self requestRemoteConfigWithForceUpdate:YES completion:^(BOOL success, NSDictionary<NSString *,id> * _Nullable config) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        @try {
            SALogDebug(@"【remote config】The request result: success is %d, config is %@", success, config);

            [strongSelf hideIndicator];
            
            if (success && config) {
                // 远程配置
                NSDictionary<NSString *, id> *remoteConfig = [strongSelf extractRemoteConfig:config];
                [strongSelf handleRemoteConfig:remoteConfig withLastestVersion:lastestVersion];
            } else {
                [strongSelf showRequestRemoteConfigFailedAlert];
            }
        } @catch (NSException *exception) {
            SALogError(@"【remote config】%@ error: %@", strongSelf, exception);
        }
    }];
}

- (void)handleRemoteConfig:(NSDictionary<NSString *, id> *)remoteConfig withLastestVersion:(NSString *)lastestVersion {
    if (![self checkRemoteConfig:remoteConfig withLastestVersion:lastestVersion]) {
        return;
    }
    
    NSMutableDictionary<NSString *, id> *eventMDic = [NSMutableDictionary dictionaryWithDictionary:remoteConfig];
    eventMDic[@"debug"] = @YES;
    [self trackAppRemoteConfigChanged:eventMDic];
    
    NSMutableDictionary<NSString *, id> *enableMDic = [NSMutableDictionary dictionaryWithDictionary:remoteConfig];
    enableMDic[@"localLibVersion"] = self.options.currentLibVersion;
    [self enableRemoteConfig:enableMDic];
}

- (BOOL)checkRemoteConfig:(NSDictionary<NSString *, id> *)remoteConfig withLastestVersion:(NSString *)lastestVersion {
    NSString *title = @"提示";
    NSString *message = @"远程配置校验通过";
    BOOL isCheckPassed = YES;
    
    NSString *currentLastestVersion = remoteConfig[@"configs"][@"nv"];
    if (![lastestVersion isEqualToString:currentLastestVersion]) {
        title = @"信息版本不一致";
        message = [NSString stringWithFormat:@"获取到采集控制信息的版本：%@，二维码信息的版本：%@，请稍后重新扫描二维码", currentLastestVersion, lastestVersion];
        isCheckPassed = NO;
    }

    [self showCheckRemoteConfigVersionAlertWithTitle:title message:message];
    
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
