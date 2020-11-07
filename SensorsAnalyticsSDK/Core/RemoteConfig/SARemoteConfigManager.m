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

@property (nonatomic, strong) SARemoteConfigMode *mode;

@end

@implementation SARemoteConfigManager

#pragma mark - Life Cycle

+ (void)startWithRemoteConfigOptions:(SARemoteConfigOptions *)options {
    [SARemoteConfigManager sharedInstance].mode = [[SARemoteConfigCommonMode alloc] initWithRemoteConfigOptions:options];
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

- (void)enableLocalRemoteConfig {
    if ([self.mode respondsToSelector:@selector(enableLocalRemoteConfig)]) {
        [self.mode enableLocalRemoteConfig];
    }
}

- (void)tryToRequestRemoteConfig {
    if ([self.mode respondsToSelector:@selector(tryToRequestRemoteConfig)]) {
        [self.mode tryToRequestRemoteConfig];
    }
}

- (void)cancelRequestRemoteConfig {
    if ([self.mode respondsToSelector:@selector(cancelRequestRemoteConfig)]) {
        [self.mode cancelRequestRemoteConfig];
    }
}

- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate {
    if ([self.mode respondsToSelector:@selector(retryRequestRemoteConfigWithForceUpdateFlag:)]) {
        [self.mode retryRequestRemoteConfigWithForceUpdateFlag:isForceUpdate];
    }
}

- (BOOL)isBlackListContainsEvent:(NSString *)event {
    return [self.mode isBlackListContainsEvent:event];
}

- (void)handleRemoteConfigURL:(NSURL *)url {
    SARemoteConfigOptions *options = self.mode.options;
    SARemoteConfigModel *model = self.mode.model;
    
    self.mode = [[SARemoteConfigCheckMode alloc] initWithRemoteConfigOptions:options remoteConfigModel:model];
    
    if ([self.mode respondsToSelector:@selector(handleRemoteConfigURL:)]) {
        [self.mode handleRemoteConfigURL:url];
    }
}

- (BOOL)isRemoteConfigURL:(NSURL *)url {
    return [url.host isEqualToString:@"sensorsdataremoteconfig"];
}

- (BOOL)canHandleURL:(NSURL *)url {
    return [self isRemoteConfigURL:url];
}

#pragma mark - Getters and Setters

- (BOOL)isDisableSDK {
    return self.mode.isDisableSDK;
}

- (NSInteger)autoTrackMode {
    return self.mode.autoTrackMode;
}

@end
