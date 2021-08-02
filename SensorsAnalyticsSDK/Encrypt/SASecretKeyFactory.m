//
// SASecretKeyFactory.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/4/20.
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

#import "SASecretKeyFactory.h"
#import "SAConfigOptions.h"
#import "SASecretKey.h"
#import "SAValidator.h"
#import "SAJSONUtil.h"
#import "SAECCEncryptor.h"
#import "SAAESEncryptor.h"
#import "SARSAEncryptor.h"

static NSString *const kSAEncryptVersion = @"pkv";
static NSString *const kSAEncryptPublicKey = @"public_key";
static NSString *const kSAEncryptType = @"type";
static NSString *const kSAEncryptTypeSeparate = @"+";

@implementation SASecretKeyFactory

+ (SASecretKey *)generateSecretKeyWithRemoteConfig:(NSDictionary *)remoteConfig encryptorChecker:(EncryptorChecker)encryptorChecker {
    if (!remoteConfig) {
        return nil;
    }

    // 国密插件化新增逻辑，只处理 key_v2 参数，当 type 不匹配时走老逻辑
    NSDictionary *newVersionKey = remoteConfig[@"key_v2"];
    SASecretKey *secKey = [SASecretKeyFactory createSecretKey:newVersionKey encryptorChecker:encryptorChecker];
    if (secKey) {
        return secKey;
    }

    // 1.0 历史版本逻辑，只处理 key 字段中内容
    NSDictionary *oldKey = remoteConfig[@"key"];
    NSString *eccContent = oldKey[@"key_ec"];

    // 当 key_ec 存在且加密库存在时，使用 EC 加密插件
    // 不论秘钥是否创建成功，都不再切换使用其他加密插件

    // 这里为了检查 ECC 插件是否存在，手动生成 ECC 模拟秘钥
    SASecretKey *eccSimulator = [[SASecretKey alloc] initWithKey:@"" version:0 asymmetricEncryptType:kSAAlgorithmTypeECC symmetricEncryptType:kSAAlgorithmTypeAES];
    if (eccContent && encryptorChecker(eccSimulator)) {
        NSDictionary *config = [SAJSONUtil JSONObjectWithString:eccContent];
        return [SASecretKeyFactory createECCSecretKey:config];
    }

    // 当远程配置不包含自定义秘钥且 EC 不可用时，使用 RSA 秘钥
    return [SASecretKeyFactory createRSASecretKey:oldKey];
}

#pragma mark - Encryptor Plugin 2.0
+ (SASecretKey *)createSecretKey:(NSDictionary *)config encryptorChecker:(EncryptorChecker)encryptorChecker {
    // key_v2 不存在时直接跳过 2.0 逻辑
    if (!config) {
        return nil;
    }

    NSNumber *pkv = config[kSAEncryptVersion];
    NSString *type = config[kSAEncryptType];
    NSString *publicKey = config[kSAEncryptPublicKey];

    // 检查相关参数是否有效
    if (!pkv || ![SAValidator isValidString:type] || ![SAValidator isValidString:publicKey]) {
        return nil;
    }

    NSArray *types = [type componentsSeparatedByString:kSAEncryptTypeSeparate];
    // 当 type 分隔数组个数小于 2 时 type 不合法，不处理秘钥信息
    if (types.count < 2) {
        return nil;
    }

    // 非对称加密类型，例如: SM2
    NSString *asymmetricType = types[0];

    // 对称加密类型，例如: SM4
    NSString *symmetricType = types[1];

    SASecretKey *secretKey = [[SASecretKey alloc] initWithKey:publicKey version:[pkv integerValue] asymmetricEncryptType:asymmetricType symmetricEncryptType:symmetricType];

    // 检查秘钥是否存在对应加密器
    if (!encryptorChecker(secretKey)) {
        return nil;
    }

    return secretKey;
}

#pragma mark - Encryptor Plugin 1.0
+ (SASecretKey *)createECCSecretKey:(NSDictionary *)config {
    if (![SAValidator isValidDictionary:config]) {
        return nil;
    }
    NSNumber *pkv = config[kSAEncryptVersion];
    NSString *publicKey = config[kSAEncryptPublicKey];
    NSString *type = config[kSAEncryptType];
    if (!pkv || ![SAValidator isValidString:type] || ![SAValidator isValidString:publicKey]) {
        return nil;
    }
    NSString *key = [NSString stringWithFormat:@"%@:%@", type, publicKey];
    return [[SASecretKey alloc] initWithKey:key version:[pkv integerValue] asymmetricEncryptType:type symmetricEncryptType:kSAAlgorithmTypeAES];
}

+ (SASecretKey *)createRSASecretKey:(NSDictionary *)config {
    if (![SAValidator isValidDictionary:config]) {
        return nil;
    }
    NSNumber *pkv = config[kSAEncryptVersion];
    NSString *publicKey = config[kSAEncryptPublicKey];
    if (!pkv || ![SAValidator isValidString:publicKey]) {
        return nil;
    }
    return [[SASecretKey alloc] initWithKey:publicKey version:[pkv integerValue] asymmetricEncryptType:kSAAlgorithmTypeRSA symmetricEncryptType:kSAAlgorithmTypeAES];
}

@end
