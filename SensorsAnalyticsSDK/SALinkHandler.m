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
#import "SAConstants+Private.h"
#import "SAURLUtils.h"
#import "SAFileStore.h"
#import "SALog.h"

@interface SALinkHandler ()

/// 包含 SDK 预置属性和用户自定义属性
@property (nonatomic, strong) NSMutableDictionary *utms;
@property (nonatomic, copy) NSDictionary *latestUtms;
/// 预置属性列表
@property (nonatomic, copy) NSSet *presetUtms;
/// 过滤后的用户自定义属性
@property (nonatomic, copy) NSSet *sourceChannels;

/// SDK初始化时的 ConfigOptions
@property (nonatomic, strong) SAConfigOptions *configOptions;

@end

static NSString *const kSavedDeepLinkInfoFileName = @"latest_utms";

@implementation SALinkHandler

- (instancetype)initWithConfigOptions:(SAConfigOptions *)configOptions {
    self = [super init];
    if (self) {
        _configOptions = configOptions;
        // 设置需要解析的预置属性名
        _presetUtms = [NSSet setWithObjects:@"utm_campaign", @"utm_content", @"utm_medium", @"utm_source", @"utm_term", nil];
        _utms = [NSMutableDictionary dictionary];

        [self filterInvalidSourceChannnels];
        [self unarchiveSavedDeepLinkInfo];
        [self handleLaunchOptions:_configOptions.launchOptions];
    }
    return self;
}

- (void)filterInvalidSourceChannnels {
    NSSet *reservedPropertyName = sensorsdata_reserved_properties();
    NSMutableSet *set = [[NSMutableSet alloc] init];
    // 将用户自定义属性中与 SDK 保留字段相同的字段过滤掉
    for (NSString *name in _configOptions.sourceChannels) {
        if (![reservedPropertyName containsObject:name]) {
            [set addObject:name];
        } else {
            // 这里只做 LOG 提醒
            SALogError(@"deeplink source channel property [%@] is invalid!!!", name);
        }
    }
    _sourceChannels = set;
}

- (void)unarchiveSavedDeepLinkInfo {
    if (!_configOptions.enableSaveDeepLinkInfo) {
        [SAFileStore archiveWithFileName:kSavedDeepLinkInfoFileName value:@{}];
        return;
    }

    NSDictionary *local = [SAFileStore unarchiveWithFileName:kSavedDeepLinkInfoFileName];
    if (!local) {
        return;
    }

    NSMutableDictionary *latest = [NSMutableDictionary dictionary];
    for (NSString *name in _presetUtms) {
        NSString *newName = [NSString stringWithFormat:@"$latest_%@", name];
        if (local[newName]) {
            latest[newName] = local[newName];
        }
    }
    // 升级版本时 sourceChannels 可能会发生变化，过滤掉本次 sourceChannels 中已不包含的字段
    for (NSString *name in _sourceChannels) {
        NSString *newName = [NSString stringWithFormat:@"_latest_%@", name];
        if (local[newName]) {
            latest[newName] = local[newName];
        }
    }
    _latestUtms = latest;
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
- (void)updateSavedChannelProperties {
    if (!_configOptions.enableSaveDeepLinkInfo) {
        return;
    }
    NSDictionary *value = _latestUtms ?: [NSDictionary dictionary];
    [SAFileStore archiveWithFileName:kSavedDeepLinkInfoFileName value:value];
}

#pragma mark - parse utms
- (BOOL)canHandleURL:(NSURL *)url {
    if (![url isKindOfClass:NSURL.class]) {
        return NO;
    }
    NSDictionary *queryItems = [SAURLUtils queryItemsWithURL:url];
    for (NSString *key in _presetUtms) {
        if (queryItems[key]) {
            return YES;
        }
    }
    for (NSString *key in _sourceChannels) {
        if (queryItems[key]) {
            return YES;
        }
    }
    return [self isValidDeepLinkURL:url];
}

// 解析冷启动来源渠道信息
- (void)handleLaunchOptions:(NSDictionary *)launchOptions {
    if (![launchOptions isKindOfClass:NSDictionary.class]) {
        return;
    }
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
    if (![url isKindOfClass:NSURL.class]) {
        return;
    }

    // 当客户唤起 App 且 deeplink 是合法 URL 时，直接清除上一次的 utm 信息
    [self clearUtmProperties];
    _latestUtms = @{};
    // 将 $deeplink_url 加入到 $AppStart 和 第一个 $ViewScreen 事件中
    _utms[@"$deeplink_url"] = url.absoluteString;

    if ([self isValidDeepLinkURL:url]) {
        [self requestForDeepLinkInfoWithURL:url];
        return;
    }

    NSDictionary *queryItems = [SAURLUtils queryItemsWithURL:url];
    [self parseUtmsWithDictionary:queryItems];
}

#pragma mark - Local Mode
//解析渠道信息字段
- (void)parseUtmsWithDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:NSDictionary.class]) {
        return;
    }

    NSMutableDictionary *latest = [NSMutableDictionary dictionary];
    BOOL coverLastInfo = NO;
    for (NSString *name in _presetUtms) {
        NSString *value = [dictionary[name] stringByRemovingPercentEncoding];
        // 字典中只要当前 name 的值存在（不论值是否为空字符串），就需要将上次的 latest utms 覆盖
        if (value) {
            coverLastInfo = YES;
        }

        // 只有字典中 name 对应的值不为空字符串时才需要添加到 latest utms 中
        // 即只有对应渠道消息有内容时才需要加到埋点数据中
        if (value.length > 0) {
            NSString *utmKey = [NSString stringWithFormat:@"$%@", name];
            _utms[utmKey] = value;
            NSString *latestKey = [NSString stringWithFormat:@"$latest_%@", name];
            latest[latestKey] = value;
        }
    }

    for (NSString *name in _sourceChannels) {
        NSString *value = [dictionary[name] stringByRemovingPercentEncoding];
        // 字典中只要当前 name 的值存在（不论值是否为空字符串），就需要将上次的 latest utms 覆盖
        if (value) {
            coverLastInfo = YES;
        }
        // 只有字典中 name 对应的值不为空字符串时才需要添加到 latest utms 中
        // 即只有对应渠道消息有内容时才需要加到埋点数据中
        if (value.length > 0) {
            _utms[name] = value;
            NSString *latestKey = [NSString stringWithFormat:@"_latest_%@", name];
            latest[latestKey] = value;
        }
    }

    // latest utms 字段在 App 销毁前一直保存在内存中
    // 当 coverLastInfo 为 YES 时，表示本次渠道信息解析中有相关渠道参数字段（不论参数内容是否为空）
    if (coverLastInfo) {
        _latestUtms = latest;
        [self updateSavedChannelProperties];
    }
    [self trackAppDeepLinkLaunchEvent];
}

- (void)trackAppDeepLinkLaunchEvent {
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    [props addEntriesFromDictionary:[self utmProperties]];
    [props addEntriesFromDictionary:[self latestUtmProperties]];
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppDeeplinkLaunch" withProperties:props];
}

#pragma mark - Server Mode
- (BOOL)isValidDeepLinkURL:(NSURL *)url {
    NSString *urlStr = url.absoluteString;
    NSString *host = [[SensorsAnalyticsSDK sharedInstance] network].serverURL.host;
    NSString *universalLink = [NSString stringWithFormat:@"%@/sd", host];
    NSString *schemeLink = @"sensorsdata/deeplink";
    return ([urlStr containsString:universalLink] || [urlStr containsString:schemeLink]);
}

- (NSURLRequest *)buildRequestWithURL:(NSURL *)url {
    NSURL *serverURL = [[[SensorsAnalyticsSDK sharedInstance] network] serverURL];
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = serverURL.scheme;
    components.host = serverURL.host;
    components.path = @"/api/v2/sa/channel_accounts/channel_deeplink_param";
#warning 这里需要确认使用的最后一段 path 还是倒数第二段 path
    NSArray *pathComponent = [[url.pathComponents reverseObjectEnumerator] allObjects];
    components.query = [NSString stringWithFormat:@"key=%@&system_type=IOS",pathComponent[1]];
    NSURL *URL = [components URL];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.timeoutInterval = 60;
    [request setHTTPMethod:@"GET"];
    return request;
}

- (void)requestForDeepLinkInfoWithURL:(NSURL *)url {

    [self trackAppDeepLinkLaunchEvent];

    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    NSURLRequest *request = [self buildRequestWithURL:url];
    NSURLSessionDataTask *task = [[SensorsAnalyticsSDK sharedInstance].network dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
        NSTimeInterval interval = ([[NSDate date] timeIntervalSince1970] - start);

        NSDictionary *result;
        BOOL success = NO;
        if (response.statusCode == 200) {
            result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSString *errorMsg = result[@"errorMsg"];
            [self parseUtmsWithDictionary:result[@"channel_params"]];
            success = (errorMsg.length <= 0);
        }
        [self trackDeeplinkMatchedResult:result interval:interval];
        if (self.callback) {
            self.callback(result[@"page_params"], success, interval);
        }
    }];
    [task resume];
}

- (void)trackDeeplinkMatchedResult:(NSDictionary *)result interval:(NSTimeInterval)interval {
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    props[@"$event_duration"] = @(interval);
    props[@"$deeplink_options"] = result[@"page_params"];
    props[@"$deeplink_match_fail_reason"] = result[@"errMsg"];
//    [props addEntriesFromDictionary:[self utmProperties]];
    [[SensorsAnalyticsSDK sharedInstance] track:@"$DeeplinkMatchedResult" withProperties:props];
}

@end
