//
// SAECCEncryptor.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/12/2.
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

#import "SAECCEncryptor.h"
#import "SAValidator.h"
#import "SALog.h"

NSString * const kSAEncryptECCPrefix = @"EC:";
NSString * const kSAEncryptECCClassName = @"SACryptoppECC";
NSString * const kSAAsymmetricEncryptTypeECC = @"EC";

typedef NSString* (*SAEEncryptImplementation)(Class, SEL, NSString *, NSString *);

@implementation SAECCEncryptor

- (NSString *)configWithSecretKey:(NSString *)secretKey {
    if (![SAValidator isValidString:secretKey]) {
        SALogError(@"Enable ECC encryption but the secret key is invalid!");
        return nil;
    }

    if (![secretKey hasPrefix:kSAEncryptECCPrefix]) {
        SALogError(@"Enable ECC encryption but the secret key is not ECC key!");
        return nil;
    }

    return [secretKey substringFromIndex:[kSAEncryptECCPrefix length]];
}

#pragma mark - Public Methods
- (NSString *)encryptSymmetricKey:(NSData *)obj publicKey:(NSString *)publicKey {
    if (![SAValidator isValidData:obj]) {
        SALogError(@"Enable ECC encryption but the input obj is invalid!");
        return nil;
    }

    // 去除非对称秘钥公钥中的前缀内容，返回实际的非对称秘钥公钥内容
    NSString *asymmetricKey = [self configWithSecretKey:publicKey];
    if (![SAValidator isValidString:asymmetricKey]) {
        SALogError(@"Enable ECC encryption but the public key is invalid!");
        return nil;
    }
    
    Class class = NSClassFromString(kSAEncryptECCClassName);
    SEL selector = NSSelectorFromString(@"encrypt:withPublicKey:");
    IMP methodIMP = [class methodForSelector:selector];
    if (methodIMP) {
        NSString *string = [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
        return ((SAEEncryptImplementation)methodIMP)(class, selector, string, asymmetricKey);
    }
    
    return nil;
}

@end
