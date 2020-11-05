//
// SARemoteConfigManager.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/11/5.
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

@interface SARemoteConfigManager ()

@property (nonatomic, strong) SARemoteConfigProcessOptions *options;
@property (nonatomic, strong) SARemoteConfigProcess *process;

@end

@implementation SARemoteConfigManager

#pragma mark - Life Cycle

+ (void)startWithRemoteConfigProcessOptions:(SARemoteConfigProcessOptions *)processOptions {
    [SARemoteConfigManager sharedInstance].options = processOptions;
    [SARemoteConfigManager sharedInstance].process = [[SARemoteConfigCommonProcess alloc] initWithRemoteConfigProcessOptions:processOptions];
}

+ (instancetype)sharedInstance {
    static SARemoteConfigManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SARemoteConfigManager alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Public

- (void)configLocalRemoteConfigModel {
    if ([self.process respondsToSelector: @selector(configLocalRemoteConfigModel)]) {
        [self.process configLocalRemoteConfigModel];
    }
}

- (void)requestRemoteConfig {
    if ([self.process respondsToSelector:@selector(requestRemoteConfig)]) {
        [self.process requestRemoteConfig];
    }
}

- (void)cancelRequestRemoteConfig {
    if ([self.process respondsToSelector:@selector(cancelRequestRemoteConfig)]) {
        [self.process cancelRequestRemoteConfig];
    }
}

- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate {
    if ([self.process respondsToSelector:@selector(retryRequestRemoteConfigWithForceUpdateFlag:)]) {
        [self.process retryRequestRemoteConfigWithForceUpdateFlag:isForceUpdate];
    }
}

- (BOOL)isBlackListContainsEvent:(NSString *)event {
    return [self.process isBlackListContainsEvent:event];
}

- (void)handleRemoteConfigURL:(NSURL *)url {
    self.process = [[SARemoteConfigCheckProcess alloc] initWithRemoteConfigProcessOptions:self.options];
    
    if ([self.process respondsToSelector:@selector(handleRemoteConfigURL:)]) {
        [self.process handleRemoteConfigURL:url];
    }
}

- (BOOL)isRemoteConfigURL:(NSURL *)url {
    return [url.host isEqualToString:@"remoteconfig"];
}

- (BOOL)canHandleURL:(NSURL *)url {
    return [self isRemoteConfigURL:url];
}

#pragma mark - Getters and Setters

- (BOOL)isDisableSDK {
    return self.process.isDisableSDK;
}

- (NSInteger)autoTrackMode {
    return self.process.autoTrackMode;
}

@end
