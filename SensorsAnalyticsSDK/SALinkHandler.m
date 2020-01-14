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
#import "NSURL+URLUtils.h"
#import "SAFileStore.h"
#import "SALogger.h"

@interface SALinkHandler ()

@property (nonatomic, strong) NSDictionary *utms;
@property (nonatomic, strong) NSDictionary *customUtms;
@property (nonatomic, strong) NSDictionary *latestUtms;

@property (nonatomic, strong) NSArray *presetUtms;

@end

static NSString *const kLocalUtmsFileName = @"latest_utms";

@implementation SALinkHandler

- (NSArray *)presetUtms {
    return @[@"utm_campaign", @"utm_content", @"utm_medium", @"utm_source", @"utm_term"];
}

- (void)setEnableSaveUtm:(BOOL)enableSaveUtm {
    _enableSaveUtm = enableSaveUtm;
    [self updateLocalLatestUtms];
}

#pragma mark - utm properties
- (nullable NSDictionary *)latestUtmProperties {
    // 热启动时会触发，直接读取内存中 latest utms 数据
    if (_latestUtms) {
        return _latestUtms;
    }
    // 只在冷启动时会触发，当不需要本地存储时，直接返回空字典
    if (!_enableSaveUtm) {
        _latestUtms = @{};
        return _latestUtms;
    }
    // 只在冷启动时会触发，从本地文件读取数据
    _latestUtms = [SAFileStore unarchiveWithFileName:kLocalUtmsFileName];
    return _latestUtms;
}

- (nullable NSDictionary *)utmProperties:(BOOL)reset {
    // 在 App 启动后触发第一个页面浏览时重置 utms 和 custom utms
    // 如果 $AppViewScreen 比 $AppStart 先触发可能会造成 AppStart 缺少 utms 及 custom utms 参数
    if (!_utms && !_customUtms) {
        return nil;
    }
    NSDictionary *utms = [_utms copy];
    NSDictionary *customsUtms = [_customUtms copy];
    if (reset) {
        _utms = @{};
        _customUtms = @{};
    }
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    [properties addEntriesFromDictionary:utms];
    [properties addEntriesFromDictionary:customsUtms];
    return properties;
}

#pragma mark - save latest utms in local file
- (void)updateLocalLatestUtms {
    // 当 utm 需要存入本地且当前没有获取到 latestUtms 时，不更新本地数据。
    // 即继续使用上次本地保存的 latest utms
    if (_enableSaveUtm && !_latestUtms) {
        return;
    }
    NSDictionary *value = _enableSaveUtm ? _latestUtms : @{};
    [SAFileStore archiveWithFileName:kLocalUtmsFileName value:(value ?: @{})];
}

#pragma mark - parse utms
- (BOOL)canHandleURL:(NSURL *)url {
    if (!url) {
        return NO;
    }
    NSDictionary *queryItems = [NSURL queryItemsWithURL:url];
    for (NSString *key in queryItems) {
        if ([self.presetUtms containsObject:key]) {
            return YES;
        }
        if ([self.customSourceChanels containsObject:key]) {
            return YES;
        }
    }
    return NO;
}

- (void)handleLaunchOptions:(NSDictionary *)launchOptions {
    if ([launchOptions.allKeys containsObject:UIApplicationLaunchOptionsURLKey]) {
        //通过 SchemeLink 唤起 App
        [self handleDeepLink:launchOptions[UIApplicationLaunchOptionsURLKey]];
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    else if (@available(iOS 8.0, *)) {
        NSDictionary *userActivityDictionary = launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey];
        if ([userActivityDictionary[UIApplicationLaunchOptionsUserActivityTypeKey] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
            //通过 UniversalLink 唤起 App
            NSUserActivity *userActivity = [userActivityDictionary objectForKey:@"UIApplicationLaunchOptionsUserActivityKey"];
            [self handleDeepLink:userActivity.webpageURL];
        } else {
            //不是 UniversalLink 唤起的 App，这里不做处理
        }
    }
#endif
    else {
        // 本次冷启动不是 DeepLink 唤起的，不做处理
    }
}

- (void)handleDeepLink:(NSURL *)url {
    if (![self canHandleURL:url]) {
        return;
    }
    NSDictionary *queryItems = [NSURL queryItemsWithURL:url];
    [self parseUtmsWithDictionary:queryItems];
}

- (void)parseUtmsWithDictionary:(NSDictionary *)dictionary {
    //解析预置渠道信息字段
    NSMutableDictionary *utms = [NSMutableDictionary dictionary];
    NSMutableDictionary *latest = [NSMutableDictionary dictionary];

    //解析客户预留渠道信息字段
    NSMutableDictionary *custom = [NSMutableDictionary dictionary];
    BOOL saveUtm = NO;
    for (NSString *key in dictionary) {
        // URL 解析出来的 value 一定是 NSString 类型
        NSString *value = dictionary[key];
        if ([self.presetUtms containsObject:key]) {
            saveUtm = YES;
            if (![value isEqualToString:@""]) {
                NSString *utmKey = [NSString stringWithFormat:@"$%@",key];
                [utms setValue:value forKey:utmKey];
                NSString *latestKey = [NSString stringWithFormat:@"$latest_%@",key];
                [latest setValue:value forKey:latestKey];
            }
        }
        if ([self.customSourceChanels containsObject:key] && ![value isEqualToString:@""]) {
            [custom setValue:value forKey:key];
        }
    }
    // utms 和 custom utms 字段会在添加到第一个 $AppViewScreen 事件后清空
    // 当前解析为空时后续触发的 $AppStart 和第一个 $AppViewScreen 没有 utms 和 custom utms 字段
    _utms = utms;
    _customUtms = custom;

    // latest utms 字段在 App 销毁前一直保存在内存中
    // 只有当解析的 latest utms 字段存在至少一个时，才覆盖当前内存及本地的 latest utms 内容
    if (saveUtm) {
        _latestUtms = latest;
        [self updateLocalLatestUtms];
    }
}

@end
