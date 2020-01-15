//
// SALinkHandler.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/1/6.
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

#import "SALinkHandler.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "NSURL+URLUtils.h"
#import "SAFileStore.h"
#import "SALogger.h"

@interface SALinkHandler ()

/// 包含 SDK 预置属性和用户自定义属性
@property (nonatomic, strong) NSDictionary *utms;
@property (nonatomic, strong) NSDictionary *latestUtms;
/// 预置属性列表
@property (nonatomic, strong) NSSet *presetUtms;

@property (nonatomic, strong) SAConfigOptions *configOptions;

@end

static NSString *const kLocalUtmsFileName = @"latest_utms";

@implementation SALinkHandler

- (instancetype)initWithConfigOptions:(SAConfigOptions *)configOptions {
    self = [super init];
    if (self) {
        self.configOptions = configOptions;
        [self initProperties];
    }
    return self;
}

- (void)initProperties {
    // 设置需要解析的预置属性名
    _presetUtms = [NSSet setWithObjects:@"utm_campaign", @"utm_content", @"utm_medium", @"utm_source", @"utm_term", nil];

    // 当不需要本地存储时，直接返回空字典
    if (!_configOptions.enableSaveUtm) {
        _latestUtms = @{};
    }
    [self updateLocalLatestUtms];
    [self handleLaunchOptions:_configOptions.launchOptions];
}

#pragma mark - utm properties
- (nullable NSDictionary *)latestUtmProperties {
    // 冷启动时触发，从本地文件读取数据
    if (_latestUtms == nil) {
        _latestUtms = [SAFileStore unarchiveWithFileName:kLocalUtmsFileName];
    }
    // 热启动时直接读取内存中 latest utms 数据
    return _latestUtms;
}

- (nullable NSDictionary *)utmProperties:(BOOL)reset {
    // 在 App 启动后触发第一个页面浏览时重置 utms
    // 如果 $AppViewScreen 比 $AppStart 先触发可能会造成 AppStart 缺少 utms 参数
    if (_utms.count == 0) {
        return nil;
    }
    NSDictionary *properties = [_utms copy];
    if (reset) {
        _utms = nil;
    }
    return properties;
}

#pragma mark - save latest utms in local file
- (void)updateLocalLatestUtms {
    // 当 utm 需要存入本地且当前没有获取到 latestUtms 时，不更新本地数据。
    // 触发场景为 “冷启动"，只有冷启动时 latest utms 会为 nil
    if (_configOptions.enableSaveUtm && _latestUtms == nil) {
        return;
    }
    NSDictionary *value = _configOptions.enableSaveUtm ? _latestUtms : @{};
    [SAFileStore archiveWithFileName:kLocalUtmsFileName value:(value ?: @{})];
}

#pragma mark - parse utms
- (BOOL)canHandleURL:(NSURL *)url {
    if (!url) {
        return NO;
    }
    NSDictionary *queryItems = [NSURL queryItemsWithURL:url];
    for (NSString *key in _presetUtms) {
        if ([queryItems.allKeys containsObject:key]) {
            return YES;
        }
    }
    for (NSString *key in _configOptions.sourceChannels) {
        if ([queryItems.allKeys containsObject:key]) {
            return YES;
        }
    }
    return NO;
}

// 解析冷启动来源渠道信息
- (void)handleLaunchOptions:(NSDictionary *)launchOptions {
    NSURL *url;
    if ([launchOptions.allKeys containsObject:UIApplicationLaunchOptionsURLKey]) {
        //通过 SchemeLink 唤起 App
        url = launchOptions[UIApplicationLaunchOptionsURLKey];
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    else if (@available(iOS 8.0, *)) {
        NSDictionary *userActivityDictionary = launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey];
        NSString *type = userActivityDictionary[UIApplicationLaunchOptionsUserActivityTypeKey];
        if ([type isEqualToString:NSUserActivityTypeBrowsingWeb]) {
            //通过 UniversalLink 唤起 App
            //TODO: 是否有对应常量
            NSUserActivity *userActivity = userActivityDictionary[@"UIApplicationLaunchOptionsUserActivityKey"];
            url = userActivity.webpageURL;
        }
    }
#endif
    if (![self canHandleURL:url]) {
        return;
    }
    [self handleDeepLink:url];
}

- (void)handleDeepLink:(NSURL *)url {
    NSDictionary *queryItems = [NSURL queryItemsWithURL:url];
    [self parseUtmsWithDictionary:queryItems];
}

- (void)parseUtmsWithDictionary:(NSDictionary *)dictionary {
    //解析渠道信息字段
    NSMutableDictionary *utm = [NSMutableDictionary dictionary];
    NSMutableDictionary *latest = [NSMutableDictionary dictionary];
    __block BOOL saveUtm = NO;
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL * _Nonnull stop) {
        if ([_presetUtms containsObject:key]) {
            saveUtm = YES;
            if (value.length > 0) {
                NSString *utmKey = [NSString stringWithFormat:@"$%@",key];
                [utm setValue:value forKey:utmKey];
                NSString *latestKey = [NSString stringWithFormat:@"$latest_%@",key];
                [latest setValue:value forKey:latestKey];
            }
        }
    }];

    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL * _Nonnull stop) {
        if ([_configOptions.sourceChannels containsObject:key]) {
            saveUtm = YES;
            if (value.length > 0) {
                NSString *utmKey = [NSString stringWithFormat:@"%@",key];
                [utm setValue:value forKey:utmKey];
                NSString *latestKey = [NSString stringWithFormat:@"$latest_%@",key];
                [latest setValue:value forKey:latestKey];
            }
        }
    }];

    _utms = utm;

    // latest utms 字段在 App 销毁前一直保存在内存中
    // 只要解析的 latest utms 属性存在时，就覆盖当前内存及本地的 latest utms 内容
    if (saveUtm) {
        _latestUtms = latest;
        [self updateLocalLatestUtms];
    }
}

@end
