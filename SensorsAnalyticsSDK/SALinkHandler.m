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
@property (nonatomic, strong) NSMutableDictionary *utms;
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
        // 设置需要解析的预置属性名
        _presetUtms = [NSSet setWithObjects:@"utm_campaign", @"utm_content", @"utm_medium", @"utm_source", @"utm_term", nil];
        _utms = [NSMutableDictionary dictionary];

        if (_configOptions.enableSaveUtm) {
            _latestUtms = [SAFileStore unarchiveWithFileName:kLocalUtmsFileName];
        } else {
            [SAFileStore archiveWithFileName:kLocalUtmsFileName value:@{}];
        }
        [self handleLaunchOptions:_configOptions.launchOptions];
    }
    return self;
}

#pragma mark - utm properties
- (nullable NSDictionary *)latestUtmProperties {
    return [_latestUtms copy];
}

- (NSDictionary *)utmProperties {
    return [_utms copy];
}

- (void)clearUtmProperties {
    [_utms removeAllObjects];
}

#pragma mark - save latest utms in local file
- (void)updateLocalLatestUtms {
    if (!_configOptions.enableSaveUtm) {
        return;
    }
    NSDictionary *value = _latestUtms ?: [NSDictionary dictionary];
    [SAFileStore archiveWithFileName:kLocalUtmsFileName value:value];
}

#pragma mark - parse utms
- (BOOL)canHandleURL:(NSURL *)url {
    if (!url) {
        return NO;
    }
    NSDictionary *queryItems = [NSURL queryItemsWithURL:url];
    for (NSString *key in _presetUtms) {
        if (queryItems[key]) {
            return YES;
        }
    }
    for (NSString *key in _configOptions.sourceChannels) {
        if (queryItems[key]) {
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
    [_utms removeAllObjects];
    __block NSMutableDictionary *latest;

    void(^handleMatch)(NSString *, NSString *) = ^(NSString *name, NSString *utmPrefix) {
        NSString *value = dictionary[name];
        if (value) {
            latest = latest ?: [NSMutableDictionary dictionary];
        }
        if (value.length > 0) {
            NSString *utmKey = [NSString stringWithFormat:@"%@%@",utmPrefix , name];
            self.utms[utmKey] = value;
            NSString *latestKey = [NSString stringWithFormat:@"$latest_%@", name];
            latest[latestKey] = value;
        }
    };

    for (NSString *name in _presetUtms) {
        handleMatch(name, @"$");
    }

    for (NSString *name in _configOptions.sourceChannels) {
        handleMatch(name, @"");
    }

    // latest utms 字段在 App 销毁前一直保存在内存中
    // 只要解析的 latest utms 属性存在时，就覆盖当前内存及本地的 latest utms 内容
    if (latest) {
        _latestUtms = latest;
        [self updateLocalLatestUtms];
    }
}

@end
