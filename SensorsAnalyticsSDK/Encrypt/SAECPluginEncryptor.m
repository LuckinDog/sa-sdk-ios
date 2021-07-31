//
// SAECPluginEncryptor.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/4/14.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAECPluginEncryptor.h"
#import "SAAESEncryptor.h"
#import "SAECEncryptor.h"
#import "SAAlgorithmProtocol.h"

@interface SAECPluginEncryptor ()

@property (nonatomic, strong) SAAESEncryptor *aesEncryptor;
@property (nonatomic, strong) SAECEncryptor *ecEncryptor;

@end

@implementation SAECPluginEncryptor

- (instancetype)init {
    // 当未集成 EC 库时，EC 加密插件无法正常使用
    if (![SAECEncryptor isAvailable]) {
        return nil;
    }

    self = [super init];
    if (self) {
        _aesEncryptor = [[SAAESEncryptor alloc] init];
        _ecEncryptor = [[SAECEncryptor alloc] init];
    }
    return self;
}

- (NSString *)symmetricEncryptType {
    return [_aesEncryptor algorithm];
}

- (NSString *)asymmetricEncryptType {
    return [_ecEncryptor algorithm];
}

- (NSString *)encryptEvent:(NSData *)event {
    return [_aesEncryptor encryptData:event];
}

- (NSString *)encryptSymmetricKeyWithPublicKey:(NSString *)publicKey {
    _ecEncryptor.key = publicKey;
    return [_ecEncryptor encryptData:_aesEncryptor.key];
}

@end
