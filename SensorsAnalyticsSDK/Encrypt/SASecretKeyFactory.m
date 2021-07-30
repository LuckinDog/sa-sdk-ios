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
#import "SASecretKey+Private.h"
#import "SAValidator.h"
#import "SAJSONUtil.h"
#import "SAECCEncryptor.h"
#import "SAAESEncryptor.h"
#import "SARSAEncryptor.h"

@implementation SASecretKeyFactory

+ (SASecretKey *)generateSecretKeyWithRemoteConfig:(NSDictionary *)remoteConfig checker:(BOOL(^)(NSString *type))checker {
    if (!remoteConfig) {
        return nil;
    }

    // 加密插件化 3.0 逻辑，只处理 key_v2 逻辑，当 type 不匹配时走 2.0 逻辑
    NSDictionary *newVersionKey = remoteConfig[@"key_v2"];
    SASecretKey *secKey = [SASecretKeyFactory createSecretKey:newVersionKey checker:checker];
    if (secKey) {
        return secKey;
    }

    // 历史版本逻辑，只处理 key 字段中内容
    NSDictionary *oldKey = remoteConfig[@"key"];
    NSString *eccContent = oldKey[@"key_ec"];
    NSString *ecType = @"EC+AES";
    if (eccContent && checker(ecType)) {
        // 当 key_ec 存在且加密库存在时，使用 ECC 加密插件
        // 不论秘钥是否创建成功，都不再切换使用其他加密插件
        NSDictionary *config = [SAJSONUtil JSONObjectWithString:eccContent];
        SASecretKey *secretKey = [SASecretKeyFactory createECCSecretKey:config];
        return secretKey;
    }

    // 当远程配置不包含自定义秘钥且 ECC 不可用时，使用 RSA 秘钥
    return [SASecretKeyFactory createRSASecretKey:oldKey];
}

#pragma mark - Encryptor Plgin 3.0
+ (SASecretKey *)createSecretKey:(NSDictionary *)config checker:(BOOL(^)(NSString *type))checker {
    NSString *type = config[@"type"];
    NSString *publicKey = config[@"public_key"];
    NSNumber *pkv = config[@"pkv"];
    if (!checker(type)) {
        return nil;
    }

    if (!pkv || ![SAValidator isValidString:type] || ![SAValidator isValidString:publicKey]) {
        return nil;
    }

    NSArray *types = [type componentsSeparatedByString:@"+"];
    // 当 type 分隔数组个数小于 2 时，不处理
    if (types.count < 2) {
        return nil;
    }
    NSString *asymmetricEncryptType = types[0];
    NSString *symmetricEncryptType = types[1];

    return [[SASecretKey alloc] initWithKey:publicKey version:[pkv integerValue] symmetricEncryptType:symmetricEncryptType asymmetricEncryptType:asymmetricEncryptType];
}

#pragma mark - Encryptor Plgin 2.0
+ (SASecretKey *)createECCSecretKey:(NSDictionary *)config {
    if (![SAValidator isValidDictionary:config]) {
        return nil;
    }
    NSNumber *pkv = config[@"pkv"];
    NSString *publicKey = config[@"public_key"];
    NSString *type = config[@"type"];
    if (!pkv || ![SAValidator isValidString:type] || ![SAValidator isValidString:publicKey]) {
        return nil;
    }
    NSString *key = [NSString stringWithFormat:@"%@:%@", type, publicKey];
    return [[SASecretKey alloc] initWithKey:key version:[pkv integerValue] symmetricEncryptType:kSAAlgorithmTypeAES asymmetricEncryptType:type];
}

+ (SASecretKey *)createRSASecretKey:(NSDictionary *)config {
    if (![SAValidator isValidDictionary:config]) {
        return nil;
    }
    NSNumber *pkv = config[@"pkv"];
    NSString *publicKey = config[@"public_key"];
    if (!pkv || ![SAValidator isValidString:publicKey]) {
        return nil;
    }
    return [[SASecretKey alloc] initWithKey:publicKey version:[pkv integerValue] symmetricEncryptType:kSAAlgorithmTypeAES asymmetricEncryptType:kSAAlgorithmTypeRSA];
}

@end
