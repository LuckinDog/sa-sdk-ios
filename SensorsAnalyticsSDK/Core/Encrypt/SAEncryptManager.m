//
// SAEncryptManager.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/11/25.
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

#import "SAEncryptManager.h"
#import "SAConfigOptions.h"
#import "SAValidator.h"
#import "SAURLUtils.h"
#import "SAAlertController.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAFileStore.h"
#import "SAConstants+Private.h"
#import "SAJSONUtil.h"
#import "SAGzipUtility.h"
#import "SAAESEncryptor.h"
#import "SARSAEncryptor.h"
#import "SAECCEncryptor.h"
#import "SALog.h"

static NSString * const kSAEncryptSecretKey = @"SAEncryptSecretKey";

@interface SAEncryptManager ()

@property (atomic, assign) NSInteger secretKeyVersion;
@property (atomic, copy) NSArray<id<SAEncryptorProtocol>> *encryptorArray;
@property (atomic, copy) NSString *encryptedAESKey;

@end

@implementation SAEncryptManager

#pragma mark - SAModuleProtocol

- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (enable) {
        [self updateEncryptor];
    }
}

#pragma mark - SAOpenURLProtocol

- (BOOL)canHandleURL:(nonnull NSURL *)url {
    return [url.host isEqualToString:@"encrypt"];
}

- (BOOL)handleURL:(nonnull NSURL *)url {
    NSString *message = @"当前 App 未开启加密，请开启加密后再试";

    if (self.enable) {
        NSDictionary *paramDic = [SAURLUtils queryItemsWithURL:url];
        NSString *urlVersion = paramDic[@"v"];
        NSString *urlKey = paramDic[@"key"];

        if ([SAValidator isValidString:urlVersion] && [SAValidator isValidString:urlKey]) {
            SASecretKey *secretKey = [self loadCurrentSecretKey];
            NSString *loadVersion = [@(secretKey.version) stringValue];
            // url 中的 key 为 encode 之后的
            NSString *loadKey = [secretKey.key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];

            if ([loadVersion isEqualToString:urlVersion] && [loadKey isEqualToString:urlKey]) {
                message = @"密钥验证通过，所选密钥与 App 端密钥相同";
            } else if (![SAValidator isValidString:loadKey]) {
                message = @"密钥验证不通过，App 端密钥为空";
            } else {
                message = [NSString stringWithFormat:@"密钥验证不通过，所选密钥与 App 端密钥不相同。所选密钥版本:%@，App 端密钥版本:%@", urlVersion, loadVersion];
            }
        } else {
            message = @"密钥验证不通过，所选密钥无效";
        }
    }

    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:nil message:message preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"确认" style:SAAlertActionStyleDefault handler:nil];
    [alertController show];
    return YES;
}

#pragma mark - SAEncryptModuleProtocol

- (BOOL)hasSecretKey {
    return [self isEncryptorValid];
}

- (void)saveSecretKey:(SASecretKey *)secretKey {
    if (!secretKey) {
        return;
    }

    void (^saveSecretKey)(SASecretKey *) = SensorsAnalyticsSDK.configOptions.saveSecretKey;
    if (saveSecretKey) {
        // 通过用户的回调保存公钥
        saveSecretKey(secretKey);

        [SAFileStore archiveWithFileName:kSAEncryptSecretKey value:nil];

        SALogDebug(@"Save secret key by saveSecretKey callback, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
    } else {
        // 存储到本地
        NSData *secretKeyData = [NSKeyedArchiver archivedDataWithRootObject:secretKey];
        [SAFileStore archiveWithFileName:kSAEncryptSecretKey value:secretKeyData];

        SALogDebug(@"Save secret key by localSecretKey, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
    }
}

- (SASecretKey *)loadCurrentSecretKey {
    SASecretKey *secretKey = nil;

    SASecretKey *(^loadSecretKey)(void) = SensorsAnalyticsSDK.configOptions.loadSecretKey;
    if (loadSecretKey) {
        // 通过用户的回调获取公钥
        secretKey = loadSecretKey();

        if (secretKey) {
            SALogDebug(@"Load secret key from loadSecretKey callback, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
        } else {
            SALogDebug(@"Load secret key from loadSecretKey callback failed!");
        }
    } else {
        // 通过本地获取公钥
        id secretKeyData = [SAFileStore unarchiveWithFileName:kSAEncryptSecretKey];
        secretKey = [NSKeyedUnarchiver unarchiveObjectWithData:secretKeyData];

        if (secretKey) {
            SALogDebug(@"Load secret key from localSecretKey, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
        } else {
            SALogDebug(@"Load secret key from localSecretKey failed!");
        }
    }

    return secretKey;
}

- (void)handleEncryptWithConfig:(NSDictionary *)encryptConfig {
    if (!encryptConfig) {
        return;
    }

    NSString *ecKey = encryptConfig[@"key_ec"];
    SASecretKey *secretKey = [[SASecretKey alloc] init];

    if ([SAValidator isValidString:ecKey] && NSClassFromString(@"SAECCEncrypt")) {
        NSData *data = [ecKey dataUsingEncoding:NSUTF8StringEncoding];
        if (data) {
            NSDictionary *ecKeyDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSString *type = ecKeyDic[@"type"];
            NSString *key = ecKeyDic[@"public_key"];

            secretKey.version = [ecKeyDic[@"pkv"] integerValue];
            secretKey.key = [NSString stringWithFormat:@"%@:%@", type, key];
        }
    } else {
        secretKey.version = [encryptConfig[@"pkv"] integerValue];
        secretKey.key = encryptConfig[@"public_key"];
    }

    // 存储公钥
    [self saveSecretKey:secretKey];

    // 更新加密构造器
    [self updateEncryptor];
}

- (NSDictionary *)encryptJSONObject:(id)obj {
    if (!obj) {
        SALogDebug(@"Enable encryption but the input obj is nil !");
        return nil;
    }

    if (![self isEncryptorValid]) {
        SALogDebug(@"Enable encryption but the secret key is nil !");
        return nil;
    }

    // 加密 AES 密钥
    if (![self encryptAESKey]) {
        SALogDebug(@"Enable encryption but the secret key is nil !");
        return nil;
    }

    // 使用 gzip 进行压缩
    NSData *jsonData = [SAJSONUtil JSONSerializeObject:obj];
    NSString *encodingString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSData *encodingData = [encodingString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *zippedData = [SAGzipUtility gzipData:encodingData];

    // AES128 加密数据
    id<SAEncryptorProtocol> aesEncryptor = [self.encryptorArray firstObject];
    NSString *encryptedString = [aesEncryptor encryptObject:zippedData];
    if (!encryptedString) {
        return nil;
    }

    // 封装加密的数据结构
    NSMutableDictionary *secretObj = [NSMutableDictionary dictionary];
    secretObj[@"pkv"] = @(self.secretKeyVersion);
    secretObj[@"ekey"] = self.encryptedAESKey;
    secretObj[@"payload"] = encryptedString;
    return [NSDictionary dictionaryWithDictionary:secretObj];
}

#pragma mark - Private Methods

- (void)updateEncryptor {
    // 获取公钥
    SASecretKey *secretKey = [self loadCurrentSecretKey];
    if (![SAValidator isValidString:secretKey.key]) {
        return;
    }

    self.secretKeyVersion = secretKey.version;

    NSMutableArray<id<SAEncryptorProtocol>> *encryptorMArray = [NSMutableArray array];
    if ([secretKey.key hasPrefix:kSAEncryptECCPrefix]) {
        // ECC 加密
        SAAESEncryptor *aesEncryptor = [[SAAESEncryptor alloc] initWithPublicKey:[self random16BitStringData]];
        SAECCEncryptor *eccEncryptor = [[SAECCEncryptor alloc] initWithPublicKey:secretKey.key];
        [encryptorMArray addObject:aesEncryptor];
        [encryptorMArray addObject:eccEncryptor];
    } else {
        // RSA 加密
        SAAESEncryptor *aesEncryptor = [[SAAESEncryptor alloc] initWithPublicKey:[self random16ByteData]];
        SARSAEncryptor *rsaEncryptor = [[SARSAEncryptor alloc] initWithPublicKey:secretKey.key];
        [encryptorMArray addObject:aesEncryptor];
        [encryptorMArray addObject:rsaEncryptor];
    }
    self.encryptorArray = [encryptorMArray copy];

    [self encryptAESKey];
}

- (NSData *)random16ByteData {
    unsigned char buf[16];
    arc4random_buf(buf, sizeof(buf));
    NSData *data = [NSData dataWithBytes:buf length:sizeof(buf)];
    return data;
}

- (NSData *)random16BitStringData {
    NSUInteger length = 16;
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    for (NSUInteger i = 0; i < length; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex:arc4random_uniform((uint32_t)[letters length])]];
    }
    return [randomString dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)isEncryptorValid {
    return self.encryptorArray.count == 2;
}

- (BOOL)encryptAESKey {
    if (self.encryptedAESKey) {
        return YES;
    }

    if (![self isEncryptorValid]) {
        return NO;
    }

    id<SAEncryptorProtocol> aesEncryptor = [self.encryptorArray firstObject];
    id<SAEncryptorProtocol> encryptor = [self.encryptorArray lastObject];
    self.encryptedAESKey = [encryptor encryptObject:aesEncryptor.publicKey];

    return self.encryptedAESKey != nil;
}

@end
