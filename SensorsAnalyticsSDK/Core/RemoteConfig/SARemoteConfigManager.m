//
// SARemoteConfigManager.m
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

#import "SARemoteConfigManager.h"
#import "SALog.h"
#import "SAURLUtils.h"
#import "SAConstants+Private.h"
#import "SAValidator.h"
#import "SAJSONUtil.h"

@implementation SARemoteConfigManagerOptions

@end

static NSString * const kSDKConfigKey = @"SASDKConfig";

@interface SARemoteConfigManager ()

@property (nonatomic, strong, readonly) NSURL *remoteConfigURL;
@property (nonatomic, strong, readonly) NSURL *serverURL;
@property (nonatomic, assign, readonly) BOOL isDisableDebugMode;
@property (nonatomic, copy, readonly) NSArray<NSString *> *eventBlackList;

@end

@implementation SARemoteConfigManager

@synthesize remoteConfigModel = _remoteConfigModel;

#pragma mark - Life Cycle

- (instancetype)initWithManagerOptions:(SARemoteConfigManagerOptions *)managerOptions {
    self = [super init];
    if (self) {
        _managerOptions = managerOptions;
        [self configLocalRemoteConfigModel];
    }
    return self;
}

#pragma mark - Public

- (void)configLocalRemoteConfigModel {
    NSDictionary *configDic = [[NSUserDefaults standardUserDefaults] objectForKey:kSDKConfigKey];
    [self enableRemoteConfigWithDictionary:configDic];
}

- (BOOL)isBlackListContainsEvent:(NSString *)event {
    if (![SAValidator isValidString:event]) {
        return NO;
    }
    
    return [self.eventBlackList containsObject:event];
}

- (nullable NSURLSessionTask *)functionalManagermentConfigWithOriginalVersion:(NSString *)originalVersion
                                                                latestVersion:(NSString *)latestVersion
                                                                   completion:(void(^)(BOOL success, NSDictionary<NSString *, id> *config))completion {
    
    NSURLRequest *request = [self buildFunctionalManagermentConfigRequestWithOriginalVersion:originalVersion latestVersion:latestVersion];
    if (!request) {
        return nil;
    }
    
    NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!completion) {
            return ;
        }
        NSInteger statusCode = response.statusCode;
        BOOL success = statusCode == 200 || statusCode == 304;
        NSDictionary<NSString *, id> *config = nil;
        @try{
            if (statusCode == 200 && data.length) {
                config = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            }
        } @catch (NSException *e) {
            SALogError(@"%@ error: %@", self, e);
            success = NO;
        }
        
        // 远程配置的请求回调需要在主线程做一些操作（定位和设备方向等）
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, config);
        });
    }];
    [task resume];
    return task;
}

- (NSDictionary<NSString *, id> *)extractRemoteConfig:(NSDictionary<NSString *, id> *)config {
    NSMutableDictionary<NSString *, id> *configs = [NSMutableDictionary dictionaryWithDictionary:config[@"configs"]];
    [configs removeObjectForKey:@"key"];
    
    NSMutableDictionary<NSString *, id> *remoteConfig = [NSMutableDictionary dictionaryWithDictionary:config];
    remoteConfig[@"configs"] = configs;
    
    return remoteConfig;
}

- (NSDictionary<NSString *, id> *)extractEncryptConfig:(NSDictionary<NSString *, id> *)config {
    return [config valueForKeyPath:@"configs.key"];
}

- (void)trackAppRemoteConfigChanged:(NSDictionary<NSString *, id> *)remoteConfig {
    NSString *eventConfigStr = @"";
    NSData *eventConfigData = [SAJSONUtil JSONSerializeObject:remoteConfig];
    if (eventConfigData) {
        eventConfigStr = [[NSString alloc] initWithData:eventConfigData encoding:NSUTF8StringEncoding];
    }
    self.managerOptions.trackEventBlock(SA_EVENT_NAME_APP_REMOTE_CONFIG_CHANGED, @{SA_EVENT_PROPERTY_APP_REMOTE_CONFIG : eventConfigStr});
}

#pragma mark - Private

- (NSURLRequest *)buildFunctionalManagermentConfigRequestWithOriginalVersion:(NSString *)originalVersion
                                                               latestVersion:(NSString *)latestVersion  {
    
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
            SALogError(@"URLString is malformed, nil is returned.");
            return nil;
        }
        urlComponets.query = nil;
        urlComponets.path = [urlComponets.path stringByAppendingPathComponent:@"/config/iOS.conf"];
    }

    urlComponets.query = [self buildRemoteConfigQueryWithOriginalVersion:originalVersion latestVersion:latestVersion];
    
    return [NSURLRequest requestWithURL:urlComponets.URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
}

- (NSString *)buildRemoteConfigQueryWithOriginalVersion:(NSString *)originalVersion latestVersion:(NSString *)latestVersion {
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionaryWithCapacity:4];
    params[@"v"] = originalVersion;
    params[@"nv"] = latestVersion;
    params[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    params[@"project"] = self.project;
    
    return [SAURLUtils urlQueryStringWithParams:params];
}


- (void)enableRemoteConfigWithDictionary:(NSDictionary *)configDic {
    self.remoteConfigModel = [[SARemoteConfigModel alloc] initWithDictionary:configDic];
    
    // 发送远程配置模块 Model 变化通知
    [[NSNotificationCenter defaultCenter] postNotificationName:SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION object:self.remoteConfigModel];
    
    BOOL isDisableSDK = self.isDisableSDK;
    BOOL isDisableDebugMode = self.isDisableDebugMode;
    self.managerOptions.triggerEffectBlock(isDisableSDK, isDisableDebugMode);
}

#pragma mark - Getters and Setters

- (BOOL)isDisableSDK {
    return self.remoteConfigModel.disableSDK;
}

- (NSInteger)autoTrackMode {
    return self.remoteConfigModel.autoTrackMode;
}

- (NSArray<NSString *> *)eventBlackList {
    return self.remoteConfigModel.eventBlackList;
}

- (BOOL)isDisableDebugMode {
    return self.remoteConfigModel.disableDebugMode;
}

- (NSURL *)remoteConfigURL {
    return [NSURL URLWithString:self.managerOptions.configOptions.remoteConfigURL];
}

- (NSURL *)serverURL {
    return [NSURL URLWithString:self.managerOptions.configOptions.serverURL];
}

- (NSString *)project {
    return [SAURLUtils queryItemsWithURL:self.serverURL][@"project"];
}

@end
