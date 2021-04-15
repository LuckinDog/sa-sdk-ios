//
// SAECCPluginEncryptor.m
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

#import "SAECCPluginEncryptor.h"
#import "SAAESEncryptor.h"
#import "SAECCEncryptor.h"

@interface SAECCPluginEncryptor ()

@property (nonatomic, strong) SAAESEncryptor *aesEncryptor;
@property (nonatomic, strong) SAECCEncryptor *eccEncryptor;

@end

@implementation SAECCPluginEncryptor

- (instancetype)init {
    self = [super init];
    if (self) {
        _aesEncryptor = [[SAAESEncryptor alloc] init];
        _eccEncryptor = [[SAECCEncryptor alloc] init];
    }
    return self;
}

/// 返回对称加密的类型，例如 AES-256
- (NSString *)symmetricEncryptType {
    return @"AES";
}

/// 返回非对称加密的类型，例如 RSA-3096
- (NSString *)asymmetricEncryptType {
    // TODO: ECC 类型是什么？
    return @"EC";
}

/// 返回压缩后的事件数据
/// @param event gzip 压缩后的事件数据
- (NSString *)encryptEvent:(NSData *)event {
    return [_aesEncryptor encryptData:event];
}

/// 返回压缩后的对称密钥数据
/// @param publicKey 非对称加密算法的公钥，用于加密对称密钥
- (NSString *)encryptSymmetricKeyWithPublicKey:(NSString *)publicKey {
    NSData *symmetricKey = [_aesEncryptor symmetricKey];
    return [_eccEncryptor encryptSymmetricKey:symmetricKey publicKey:publicKey];
}

#pragma mark - public method
+ (BOOL)isAvailable {
    if (!NSClassFromString(kSAEncryptECCClassName)) {
        NSAssert(NO, @"\n您使用了 ECC 密钥，但是并没有集成 ECC 加密库。\n • 如果使用源码集成 ECC 加密库，请检查是否包含名为 SAECCEncrypt 的文件? \n • 如果使用 CocoaPods 集成 SDK，请修改 Podfile 文件并增加 ECC 模块，例如：pod 'SensorsAnalyticsEncrypt'。\n");
        return NO;
    }
    return YES;
}

+ (BOOL)isECCPlugin:(NSString *)publicKey {
    return [publicKey hasPrefix:kSAEncryptECCPrefix];
}

@end
