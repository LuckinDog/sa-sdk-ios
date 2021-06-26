//
// SARemoteConfigOperator.m
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

#import "SARemoteConfigOperator.h"
#import "SALog.h"
#import "SAURLUtils.h"
#import "SAConstants+Private.h"
#import "SAValidator.h"
#import "SAJSONUtil.h"
#import "SAModuleManager.h"
#import "SARemoteConfigEventObject.h"
#import "SensorsAnalyticsSDK+Private.h"

@interface SARemoteConfigOperator ()

@property (nonatomic, copy, readonly) NSString *latestVersion;
@property (nonatomic, copy, readonly) NSString *originalVersion;
@property (nonatomic, strong, readonly) NSURL *remoteConfigURL;
@property (nonatomic, strong, readonly) NSURL *serverURL;
@property (nonatomic, assign, readonly) BOOL isDisableDebugMode;
@property (nonatomic, copy, readonly) NSArray<NSString *> *eventBlackList;

@end

@implementation SARemoteConfigOperator

#pragma mark - Public

- (BOOL)isBlackListContainsEvent:(nullable NSString *)event {
    if (![SAValidator isValidString:event]) {
        return NO;
    }
    
    return [self.eventBlackList containsObject:event];
}

- (void)requestRemoteConfigWithForceUpdate:(BOOL)isForceUpdate completion:(void (^)(BOOL success, NSDictionary<NSString *, id> * _Nullable config))completion {
    if (!completion) {
        return;
    }

    @try {
        BOOL shouldAddVersion = !isForceUpdate && [self isLibVersionUnchanged] && [self shouldAddVersionOnEnableEncrypt];
        NSString *originalVersion = shouldAddVersion ? self.originalVersion : nil;
        NSString *latestVersion = shouldAddVersion ? self.latestVersion : nil;
        
        NSURLRequest *request = [self buildURLRequestWithOriginalVersion:originalVersion latestVersion:latestVersion];
        if (!request) {
            completion(NO, nil);
            return;
        }
        
        NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
            NSInteger statusCode = response.statusCode;
            BOOL success = statusCode == 200 || statusCode == 304;
            NSDictionary<NSString *, id> *config = nil;
            @try{
                if (statusCode == 200 && data.length) {
                    config = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                }
            } @catch (NSException *e) {
                SALogError(@"【remote config】%@ error: %@", self, e);
                success = NO;
            }
            
            completion(success, config);
        }];
        [task resume];
    } @catch (NSException *e) {
        SALogError(@"【remote config】%@ error: %@", self, e);
        completion(NO, nil);
    }
}

- (NSDictionary<NSString *, id> *)extractRemoteConfig:(NSDictionary<NSString *, id> *)config {
    @try {
        NSMutableDictionary<NSString *, id> *configs = [NSMutableDictionary dictionaryWithDictionary:config[@"configs"]];
        [configs removeObjectForKey:@"key"];

        NSMutableDictionary<NSString *, id> *remoteConfig = [NSMutableDictionary dictionaryWithDictionary:config];
        remoteConfig[@"configs"] = configs;

        return remoteConfig;
    } @catch (NSException *exception) {
        SALogError(@"【remote config】%@ error: %@", self, exception);
        return nil;
    }
}

- (NSDictionary<NSString *, id> *)extractEncryptConfig:(NSDictionary<NSString *, id> *)config {
    return config[@"configs"][@"key"];
}

- (void)trackAppRemoteConfigChanged:(NSDictionary<NSString *, id> *)remoteConfig {
    NSString *eventConfigString = nil;
    NSData *eventConfigData = [SAJSONUtil JSONSerializeObject:remoteConfig];
    if (eventConfigData) {
        eventConfigString = [[NSString alloc] initWithData:eventConfigData encoding:NSUTF8StringEncoding];
    }

    SARemoteConfigEventObject *object = [[SARemoteConfigEventObject alloc] initWithEventId:kSAEventNameAppRemoteConfigChanged];
    [SensorsAnalyticsSDK.sdkInstance asyncTrackEventObject:object properties:@{kSAEventPropertyAppRemoteConfig : eventConfigString ?: @""}];
    // 触发 $AppRemoteConfigChanged 时 flush 一次
    [SensorsAnalyticsSDK.sdkInstance flush];
}

- (void)enableRemoteConfig:(NSDictionary *)config {
    self.model = [[SARemoteConfigModel alloc] initWithDictionary:config];
    
    // 发送远程配置模块 Model 变化通知
    [[NSNotificationCenter defaultCenter] postNotificationName:SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION object:self.model];
    
    BOOL isDisableSDK = self.isDisableSDK;
    BOOL isDisableDebugMode = self.isDisableDebugMode;

    if (isDisableDebugMode) {
        SAModuleManager.sharedInstance.debugMode = SensorsAnalyticsDebugOff;
        [SensorsAnalyticsSDK.sdkInstance enableLog:NO];
    }

    isDisableSDK ? [self performDisableSDKTask] : [self performEnableSDKTask];
}

#pragma mark - Private

- (void)performDisableSDKTask {
    [SensorsAnalyticsSDK.sdkInstance stopFlushTimer];

    [SensorsAnalyticsSDK.sdkInstance removeWebViewUserAgent];

    // 停止采集数据之后 flush 本地数据
    [SensorsAnalyticsSDK.sdkInstance flush];
}

- (void)performEnableSDKTask {
    [SensorsAnalyticsSDK.sdkInstance startFlushTimer];

    [SensorsAnalyticsSDK.sdkInstance appendWebViewUserAgent];
}

#pragma mark Network

- (BOOL)isLibVersionUnchanged {
    return [self.model.localLibVersion isEqualToString:SensorsAnalyticsSDK.sdkInstance.libVersion];
}

- (BOOL)shouldAddVersionOnEnableEncrypt {
    if (!self.configOptions.enableEncrypt) {
        return YES;
    }

    return SAModuleManager.sharedInstance.hasSecretKey;
}

- (NSURLRequest *)buildURLRequestWithOriginalVersion:(nullable NSString *)originalVersion latestVersion:(nullable NSString *)latestVersion {
    NSURLComponents *urlComponets = nil;
    if (self.remoteConfigURL) {
        urlComponets = [NSURLComponents componentsWithURL:self.remoteConfigURL resolvingAgainstBaseURL:YES];
    }
    if (!urlComponets.host) {
        NSURL *url = self.serverURL.lastPathComponent.length > 0 ? [self.serverURL URLByDeletingLastPathComponent] : self.serverURL;
        if (url) {
            urlComponets = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
        }
        
        if (!urlComponets.host) {
            SALogError(@"【remote config】URLString is malformed, nil is returned.");
            return nil;
        }
        urlComponets.query = nil;
        urlComponets.path = [urlComponets.path stringByAppendingPathComponent:@"/config/iOS.conf"];
    }
    
    urlComponets.query = [self buildQueryWithURL:urlComponets.URL originalVersion:originalVersion latestVersion:latestVersion];
    
    return [NSURLRequest requestWithURL:urlComponets.URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
}

- (NSString *)buildQueryWithURL:(NSURL *)url originalVersion:(NSString *)originalVersion latestVersion:(NSString *)latestVersion {
    NSDictionary *originalParams = [SAURLUtils queryItemsWithURL:url];
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionaryWithDictionary:originalParams];
    params[@"v"] = originalParams[@"v"] ?: originalVersion;
    params[@"nv"] = originalParams[@"nv"] ?: latestVersion;
    params[@"app_id"] = originalParams[@"app_id"] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    params[@"project"] = originalParams[@"project"] ?: self.project;
    
    return [SAURLUtils urlQueryStringWithParams:params];
}

#pragma mark - Getters and Setters

- (BOOL)isDisableSDK {
    return self.model.disableSDK;
}

- (NSArray<NSString *> *)eventBlackList {
    return self.model.eventBlackList;
}

- (NSString *)latestVersion {
    return self.model.latestVersion;
}

- (NSString *)originalVersion {
    return self.model.originalVersion;
}

- (BOOL)isDisableDebugMode {
    return self.model.disableDebugMode;
}

- (NSURL *)remoteConfigURL {
    return [NSURL URLWithString:self.configOptions.remoteConfigURL];
}

- (NSURL *)serverURL {
    return [NSURL URLWithString:self.configOptions.serverURL];
}

- (NSString *)project {
    return [SAURLUtils queryItemsWithURL:self.serverURL][@"project"];
}

@end
