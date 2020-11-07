//
// SARemoteConfigMode.m
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

#import "SARemoteConfigMode.h"
#import "SALog.h"
#import "SAURLUtils.h"
#import "SAConstants+Private.h"
#import "SAValidator.h"
#import "SAJSONUtil.h"

@implementation SARemoteConfigOptions
@end

@interface SARemoteConfigMode ()

@property (nonatomic, copy, readonly) NSString *latestVersion;
@property (nonatomic, copy, readonly) NSString *originalVersion;
@property (nonatomic, strong, readonly) NSURL *remoteConfigURL;
@property (nonatomic, strong, readonly) NSURL *serverURL;
@property (nonatomic, assign, readonly) BOOL isDisableDebugMode;
@property (nonatomic, copy, readonly) NSArray<NSString *> *eventBlackList;

@end

@implementation SARemoteConfigMode

#pragma mark - Life Cycle

- (instancetype)initWithRemoteConfigOptions:(SARemoteConfigOptions *)options {
    self = [super init];
    if (self) {
        _options = options;
    }
    return self;
}

#pragma mark - Public

- (BOOL)isBlackListContainsEvent:(NSString *)event {
    if (![SAValidator isValidString:event]) {
        return NO;
    }
    
    return [self.eventBlackList containsObject:event];
}

- (void)requestRemoteConfigWithForceUpdate:(BOOL)isForceUpdate completion:(void (^)(BOOL success, NSDictionary<NSString *, id> * _Nullable config))completion {
    @try {
        BOOL shouldAddVersion = !isForceUpdate && [self isLibVersionUnchanged] && [self shouldAddVersionOnEnableEncrypt];
        NSString *originalVersion = shouldAddVersion ? self.originalVersion : nil;
        NSString *latestVersion = shouldAddVersion ? self.latestVersion : nil;
        [self functionalManagermentConfigWithOriginalVersion:originalVersion latestVersion:latestVersion completion:completion];
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
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
    self.options.trackEventBlock(SA_EVENT_NAME_APP_REMOTE_CONFIG_CHANGED, @{SA_EVENT_PROPERTY_APP_REMOTE_CONFIG : eventConfigStr});
}

- (void)enableRemoteConfigWithDictionary:(NSDictionary *)configDic {
    self.model = [[SARemoteConfigModel alloc] initWithDictionary:configDic];
    
    // 发送远程配置模块 Model 变化通知
    [[NSNotificationCenter defaultCenter] postNotificationName:SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION object:self.model];
    
    BOOL isDisableSDK = self.isDisableSDK;
    BOOL isDisableDebugMode = self.isDisableDebugMode;
    self.options.triggerEffectBlock(isDisableSDK, isDisableDebugMode);
}

#pragma mark - Private

#pragma mark Network

- (BOOL)isLibVersionUnchanged {
    return [self.model.localLibVersion isEqualToString:self.options.currentLibVersion];
}

- (BOOL)shouldAddVersionOnEnableEncrypt {
    if (!self.options.configOptions.enableEncrypt) {
        return YES;
    }
    
    return self.options.encryptBuilderCreateResultBlock();
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

#pragma mark - Getters and Setters

- (BOOL)isDisableSDK {
    return self.model.disableSDK;
}

- (NSInteger)autoTrackMode {
    return self.model.autoTrackMode;
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
    return [NSURL URLWithString:self.options.configOptions.remoteConfigURL];
}

- (NSURL *)serverURL {
    return [NSURL URLWithString:self.options.configOptions.serverURL];
}

- (NSString *)project {
    return [SAURLUtils queryItemsWithURL:self.serverURL][@"project"];
}

@end
