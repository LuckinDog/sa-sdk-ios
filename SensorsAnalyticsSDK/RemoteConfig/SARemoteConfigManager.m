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
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAModuleManager.h"

@interface SARemoteConfigManager ()

@property (atomic, strong) SARemoteConfigOperator *operator;

@end

@implementation SARemoteConfigManager

#pragma mark - SAModuleProtocol

- (instancetype)init {
    self = [super init];
    if (self) {
        _operator = [[SARemoteConfigCommonOperator alloc] init];
    }
    return self;
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (enable) {
        self.operator = [[SARemoteConfigCommonOperator alloc] init];
        self.operator.configOptions = self.configOptions;
    } else {
        self.operator = nil;
    }
}

#pragma mark - SAOpenURLProtocol

- (BOOL)canHandleURL:(NSURL *)url {
    return [self isRemoteConfigURL:url];
}

- (BOOL)handleURL:(NSURL *)url {
    if (![self.operator isKindOfClass:[SARemoteConfigCheckOperator class]]) {
        SARemoteConfigModel *model = self.operator.model;
        self.operator = [[SARemoteConfigCheckOperator alloc] initWithRemoteConfigModel:model];
    }

    if ([self.operator respondsToSelector:@selector(handleRemoteConfigURL:)]) {
        return [self.operator handleRemoteConfigURL:url];
    }

    return NO;
}

#pragma mark - SARemoteConfigModuleProtocol

- (BOOL)isRemoteConfigURL:(NSURL *)url {
    return [url.host isEqualToString:@"sensorsdataremoteconfig"];
}

- (void)cancelRequestRemoteConfig {
    if ([self.operator respondsToSelector:@selector(cancelRequestRemoteConfig)]) {
        [self.operator cancelRequestRemoteConfig];
    }
}

- (void)enableLocalRemoteConfig {
    if ([self.operator respondsToSelector:@selector(enableLocalRemoteConfig)]) {
        [self.operator enableLocalRemoteConfig];
    }
}

- (void)tryToRequestRemoteConfig {
    if ([self.operator respondsToSelector:@selector(tryToRequestRemoteConfig)]) {
        [self.operator tryToRequestRemoteConfig];
    }
}

- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate {
    if ([self.operator respondsToSelector:@selector(retryRequestRemoteConfigWithForceUpdateFlag:)]) {
        [self.operator retryRequestRemoteConfigWithForceUpdateFlag:isForceUpdate];
    }
}

- (BOOL)isBlackListContainsEvent:(nullable NSString *)event {
    return [self.operator isBlackListContainsEvent:event];
}

- (BOOL)isDisableSDK {
    return self.operator.isDisableSDK;
}

- (NSInteger)autoTrackMode {
    return self.operator.autoTrackMode;
}

@end
