//
// SARemoteConfigCheckManager.m
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

#import "SARemoteConfigCheckManager.h"
#import "SAURLUtils.h"
#import "SAAlertController.h"

@interface SARemoteConfigCheckManager ()

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@end

@implementation SARemoteConfigCheckManager

- (void)handleRemoteConfigURL:(NSURL *)url {
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
    
    BOOL isCheckSuccess = YES;
    NSString *message = @"开始获取采集控制信息";
    if (![currentProject isEqualToString:project]) {
        isCheckSuccess = NO;
        message = @"App 集成的项目与电脑浏览器打开的项目不同，无法进行调试";
    } else if (![currentAppID isEqualToString:appID]) {
        isCheckSuccess = NO;
        message = @"App 与二维码对应的 App 不同，无法进行调试";
    } else if (![currentOS isEqualToString:os]) {
        isCheckSuccess = NO;
        message = @"App 与二维码对应的操作系统不同，无法进行调试";
    }
    
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:@"提示" message:message preferredStyle:SAAlertControllerStyleAlert];
    if (isCheckSuccess) {
        [alertController addActionWithTitle:@"取消" style:SAAlertActionStyleCancel handler:nil];
        [alertController addActionWithTitle:@"继续" style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
            // TODO:wq 立即请求远程配置
            [self requestRemoteConfigWithLastestVersion:lastestVersion];
        }];
    } else {
        [alertController addActionWithTitle:@"确认" style:SAAlertActionStyleDefault handler:nil];
    }
    [alertController show];
}

- (void)requestRemoteConfigWithLastestVersion:(NSString *)lastestVersion {
    // TODO:wq 首先校验 lastestVersion ？
    [self showIndicator];
    
    __weak typeof(self) weakSelf = self;
    [self functionalManagermentConfigWithOriginalVersion:nil latestVersion:nil completion:^(BOOL success, NSDictionary<NSString *,id> *config) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf hideIndicator];
        
        NSString *message = @"远程配置获取失败，请稍后再试";
        
        if (success) {
            // TODO:wq
            // 1.触发事件
            NSMutableDictionary<NSString *, id> *remoteConfig = [NSMutableDictionary dictionaryWithDictionary:[strongSelf extractRemoteConfig:config]];
            remoteConfig[@"debug"] = @YES;
            [self trackAppRemoteConfigChanged:remoteConfig];
            
            // 2.校验版本
            NSString *currentLastestVersion = remoteConfig[@"configs"][@"nv"];
            if (![currentLastestVersion isEqualToString:lastestVersion]) {
                message = [NSString stringWithFormat:@"远程配置校验不通过，二维码中的版本是：%@，当前的版本是：%@", lastestVersion, currentLastestVersion];
            } else {
                message = @"远程配置校验通过";
                // 3.立即生效
                [remoteConfig removeObjectForKey:@"debug"];
                remoteConfig[@"localLibVersion"] = self.managerOptions.currentLibVersion;
                [strongSelf enableRemoteConfigWithDictionary:remoteConfig];
            }
        }
        
        SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:@"提示" message:message preferredStyle:SAAlertControllerStyleAlert];
        [alertController addActionWithTitle:@"确认" style:SAAlertActionStyleDefault handler:nil];
        [alertController show];
    }];
}

#pragma mark Indicator

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
