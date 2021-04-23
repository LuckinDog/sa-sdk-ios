//
// SAEncryptTests.m
// SensorsAnalyticsTests
//
// Created by 彭远洋 on 2021/4/21.
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

#import <XCTest/XCTest.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import "SASecretKeyFactory.h"
#import "SAAESEncryptor.h"
#import "SASecretKeyFactory.h"
#import "SAConfigOptions.h"

#pragma mark - 测试 EC 秘钥逻辑使用
@interface SACryptoppECC : NSObject

@end

@implementation SACryptoppECC

@end

@interface SAEncryptTests : XCTestCase

@property (nonatomic, strong) SAAESEncryptor *aesEncryptor;

@end

@implementation SAEncryptTests

- (void)setUp {

    // 单元测试场景下无法正常使用 RSA 加密和 ECC 加密功能
    // 在单元测试场景下，使用 RSA 加密会返回错误状态码 errSecMissingEntitlement = -34018
    // 这里只补充 AES 对称加密逻辑，以及下发数据生成秘钥逻辑
    _aesEncryptor = [[SAAESEncryptor alloc] init];
}

// AES 解密测试
- (NSString *)aesDecrypt:(NSData *)publicKey encryptedContent:(NSString *)encryptedContent {
    NSData *data = [encryptedContent dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encryptedData = [[NSData alloc] initWithBase64EncodedData:data options:0];

    NSUInteger dataLength = [encryptedData length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          [publicKey bytes],
                                          kCCBlockSizeAES128,
                                          NULL,
                                          [encryptedData bytes],
                                          [encryptedData length],
                                          buffer,
                                          bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        NSData *result = [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
        NSRange range = NSMakeRange(16, result.length - 16);
        NSData *da = [result subdataWithRange:range];
        return [[NSString alloc] initWithData:da encoding:NSUTF8StringEncoding];
    }
    free(buffer);
    return nil;
}

- (void)testAESEncrypt {
    NSString *testContent = @"这是一段测试的字符串";
    NSString *encrypt = [_aesEncryptor encryptData:[testContent dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *decrypt = [self aesDecrypt:_aesEncryptor.key encryptedContent:encrypt];
    XCTAssertTrue([decrypt isEqualToString:testContent]);
}

- (void)testGenerateRSASecretKeyForSuccess {
    NSDictionary *mock = @{@"pkv":@(1), @"public_key":@"123"};
    SASecretKey *secretKey = [SASecretKeyFactory generateSecretKeyWithRemoteConfig:mock];
    XCTAssertTrue([secretKey.key isEqualToString:@"123"]);
    XCTAssertTrue([secretKey.symmetricEncryptType isEqualToString:@"AES"]);
    XCTAssertTrue([secretKey.asymmetricEncryptType isEqualToString:@"RSA"]);
    XCTAssertTrue(secretKey.version == 1);
}

- (void)testGenerateRSASecretKeyForFailed {
    NSDictionary *mock = @{@"pkv":@(1), @"public_key":@""};
    SASecretKey *secretKey = [SASecretKeyFactory generateSecretKeyWithRemoteConfig:mock];
    XCTAssertNil(secretKey);
}

- (void)testGenerateECCSecretKeyForSuccess {
    NSString *keyEC = @"{\"pkv\":2,\"type\":\"EC\",\"public_key\":\"123\"}";
    NSDictionary *mock = @{@"pkv":@(1), @"public_key":@"", @"key_ec":keyEC};
    SASecretKey *secretKey = [SASecretKeyFactory generateSecretKeyWithRemoteConfig:mock];
    XCTAssertTrue([secretKey.key isEqualToString:@"EC:123"]);
    XCTAssertTrue([secretKey.symmetricEncryptType isEqualToString:@"AES"]);
    XCTAssertTrue([secretKey.asymmetricEncryptType isEqualToString:@"EC"]);
    XCTAssertTrue(secretKey.version == 2);
}

- (void)testGenerateECCSecretKeyForFailed1 {
    NSString *keyEC = @"{\"pkv\":2,\"type\":\"\",\"public_key\":\"123\"}";
    NSDictionary *mock = @{@"pkv":@(1), @"public_key":@"", @"key_ec":keyEC};
    SASecretKey *secretKey = [SASecretKeyFactory generateSecretKeyWithRemoteConfig:mock];
    XCTAssertNil(secretKey);
}

- (void)testGenerateECCSecretKeyForFailed2 {
    NSString *keyEC = @"{\"pkv\":2,\"type\":\"EC\",\"public_key\":\"\"}";
    NSDictionary *mock = @{@"pkv":@(1), @"public_key":@"", @"key_ec":keyEC};
    SASecretKey *secretKey = [SASecretKeyFactory generateSecretKeyWithRemoteConfig:mock];
    XCTAssertNil(secretKey);
}

- (void)testGenerateCustomSecretKey {
    NSString *key = @"{\"pkv\":2,\"type\":\"CUSTOM\",\"public_key\":\"123\"}";
    NSDictionary *mock = @{@"pkv":@(1), @"public_key":@"", @"key_custom_placeholder":key};
    SASecretKey *secretKey = [SASecretKeyFactory generateSecretKeyWithRemoteConfig:mock];
    XCTAssertNotNil(secretKey);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
