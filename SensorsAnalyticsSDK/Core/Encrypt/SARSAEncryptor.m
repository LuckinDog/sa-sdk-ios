//
//  SARSAEncryptor.m
//  SensorsAnalyticsSDK
//
//  Created by wenquan on 2020/11/26.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SARSAEncryptor.h"
#import "SAConfigOptions.h"
#import "SAEncryptUtils.h"
#import "SALog.h"

@interface SARSAEncryptor ()

/// 初始的 AES 密钥
@property(nonatomic, copy) NSData *originalAESKey;
/// 加密的 AES 密钥
@property(nonatomic, copy) NSString *encryptedAESKey;

@end

@implementation SARSAEncryptor

#pragma mark - Life Cycle

- (instancetype)initWithSecretKey:(SASecretKey *)secretKey {
    self = [super initWithSecretKey:secretKey];
    if (self) {
        NSData *rsaEncryptData = [SAEncryptUtils RSAEncryptData:self.originalAESKey publicKey:self.secretKey.key];
        _encryptedAESKey = [rsaEncryptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    }
    return self;
}

#pragma mark - SAEncryptorProtocol

- (nullable NSDictionary *)encryptJSONObject:(id)obj {
    if (!obj) {
        SALogDebug(@"Enable RSA encryption but the input obj is nil!");
        return nil;
    }

    if (!self.secretKey || !self.encryptedAESKey) {
        SALogDebug(@"Enable RSA encryption but the secret key is nil!");
        return nil;
    }

    // 使用 gzip 进行压缩
    NSData *zippedData = [self gzipJSONObject:obj];

    // AES128 加密
    NSString *encryptString = [SAEncryptUtils AES128EncryptData:zippedData AESKey:self.originalAESKey];
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

#pragma mark – Getters and Setters

- (NSData *)originalAESKey {
    if (!_originalAESKey) {
        _originalAESKey = [SAEncryptUtils random16ByteData];
    }
    return _originalAESKey;
}

- (NSString *)encryptedAESKey {
    if (!_encryptedAESKey) {
        NSData *rsaEncryptData = [SAEncryptUtils RSAEncryptData:self.originalAESKey publicKey:self.secretKey.key];
        _encryptedAESKey = [rsaEncryptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    }
    return _encryptedAESKey;
}

@end
