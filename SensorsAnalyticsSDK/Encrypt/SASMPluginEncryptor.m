//
// SASMPluginEncryptor.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/7/21.
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

#import "SASMPluginEncryptor.h"

@interface SASMPluginEncryptor ()

@property (nonatomic, copy) NSString *symmetricKey;
@property (nonatomic, copy) NSString *symmetricInv;

@end

typedef NSString* (*SAEEncryptImplementation)(Class, SEL);
typedef NSData* (*SAEEncryptImplementation11)(Class, SEL, NSData *, NSString *, NSString *);
typedef NSString* (*SAEEncryptImplementation22)(Class, SEL, NSString *, NSString *);

@implementation SASMPluginEncryptor

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

/// 返回对称加密的类型，例如 AES
- (NSString *)symmetricEncryptType {
    return @"SM4";
}

/// 返回非对称加密的类型，例如 RSA
- (NSString *)asymmetricEncryptType {
    return @"SM2";
}

/// 返回加密后的事件数据
/// @param event gzip 压缩后的事件数据
- (NSString *)encryptEvent:(NSData *)event {
    Class class = NSClassFromString(@"SASM4Encryptor");
    if (!_symmetricKey) {
        SEL selector = NSSelectorFromString(@"createSm4Key");
        IMP methodIMP = [class methodForSelector:selector];
        if (methodIMP) {
            _symmetricKey = ((SAEEncryptImplementation)methodIMP)(class, selector);
        }
    }
    if (!_symmetricInv) {
        SEL selector = NSSelectorFromString(@"createSm4Key");
        IMP methodIMP = [class methodForSelector:selector];
        if (methodIMP) {
            _symmetricInv = ((SAEEncryptImplementation)methodIMP)(class, selector);
        }
    }

    NSData *result;
    if (_symmetricKey && _symmetricInv) {
        SEL selector = NSSelectorFromString(@"encryptData:key:IV:");
        IMP methodIMP = [class methodForSelector:selector];
        if (methodIMP) {
            result = ((SAEEncryptImplementation11)methodIMP)(class, selector, event, _symmetricKey, _symmetricInv);
        }
    }

    // Base64 编码
    NSData *base64EncodeData = [result base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];

    // 编码后加密内容
    return [[NSString alloc] initWithData:base64EncodeData encoding:NSUTF8StringEncoding];
}

/// 返回加密后的对称密钥数据
/// @param publicKey 非对称加密算法的公钥，用于加密对称密钥
- (NSString *)encryptSymmetricKeyWithPublicKey:(NSString *)publicKey {
    NSString *symmetric = [NSString stringWithFormat:@"%@%@",_symmetricInv, _symmetricKey];
    Class class = NSClassFromString(@"SASM2Encryptor");
    SEL selector = NSSelectorFromString(@"encrypt:withPublicKey:");
    IMP methodIMP = [class methodForSelector:selector];
    NSString *result;
    if (methodIMP) {
        result = ((SAEEncryptImplementation22)methodIMP)(class, selector, symmetric, publicKey);
    }
    return result;
}

@end
