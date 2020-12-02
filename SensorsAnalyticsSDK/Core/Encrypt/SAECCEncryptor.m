//
//  SAECCEncryptor.m
//  SensorsAnalyticsSDK
//
//  Created by wenquan on 2020/11/26.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAECCEncryptor.h"
#import "SAConfigOptions.h"
#import "SAEncryptUtils.h"
#import "SALog.h"

@interface SAECCEncryptor ()

/// 初始的 AES 密钥
@property(nonatomic, copy) NSString *originalAESKey;
/// 加密的 AES 密钥
@property(nonatomic, copy) NSString *encryptedAESKey;

@end

@implementation SAECCEncryptor

#pragma mark - Life Cycle

- (instancetype)initWithSecretKey:(SASecretKey *)secretKey {
    self = [super initWithSecretKey:secretKey];
    if (self) {
        _encryptedAESKey = [SAEncryptUtils eccEncryptString:self.originalAESKey publicKey:self.secretKey.key];
    }
    return self;
}

#pragma mark - SAEncryptorProtocol

- (nullable NSDictionary *)encryptJSONObject:(id)obj {
    if (!obj) {
        SALogDebug(@"Enable ECC encryption but the input obj is nil!");
        return nil;
    }

    if (!self.secretKey || !self.encryptedAESKey) {
        SALogDebug(@"Enable ECC encryption but the secret key is nil!");
        return nil;
    }

    // 使用 gzip 进行压缩
    NSData *zippedData = [self gzipJSONObject:obj];

    // AES128 加密
    NSData *aesKey = [self.originalAESKey dataUsingEncoding:NSUTF8StringEncoding];
    NSString *encryptString = [SAEncryptUtils AES128EncryptData:zippedData AESKey:aesKey];
    if (!encryptString) {
        return nil;
    }

    // 封装加密的数据结构
    NSMutableDictionary *secretObj = [NSMutableDictionary dictionary];
    secretObj[@"pkv"] = @(self.secretKey.version);
    secretObj[@"ekey"] = self.encryptedAESKey;
    secretObj[@"payload"] = encryptString;
    return [NSDictionary dictionaryWithDictionary:secretObj];
}

#pragma mark – Private



#pragma mark – Getters and Setters

- (NSString *)originalAESKey {
    if (!_originalAESKey) {
        _originalAESKey = [SAEncryptUtils random16BitString];
    }
    return _originalAESKey;
}

- (NSString *)encryptedAESKey {
    if (!_encryptedAESKey) {
        _encryptedAESKey = [SAEncryptUtils eccEncryptString:self.originalAESKey publicKey:self.secretKey.key];
    }
    return _encryptedAESKey;
}

@end
