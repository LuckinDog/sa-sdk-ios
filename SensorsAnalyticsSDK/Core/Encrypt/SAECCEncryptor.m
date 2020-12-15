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
#import "SAConstants+Private.h"

@implementation SAECCEncryptor

#pragma mark - Public Methods

- (nullable NSString *)encryptObject:(NSData *)obj {
    if (![SAValidator isValidData:obj]) {
        SALogDebug(@"Enable ECC encryption but the input obj is not NSString!");
        return nil;
    }
    
    if (![SAValidator isValidString:self.secretKey]) {
        SALogDebug(@"Enable ECC encryption but the public key is not NSString!");
        return nil;
    }
    
    if (![self.secretKey hasPrefix:kSAEncryptECCPrefix]) {
        SALogDebug(@"Enable ECC encryption but the public key is not ECC key!");
        return nil;
    }
    
    Class crypto = NSClassFromString(kSAEncryptECCClassName);
    SEL sel = NSSelectorFromString(@"encrypt:withPublicKey:");
    if ([crypto respondsToSelector:sel]) {
        NSString *string = [[NSString alloc] initWithData:(NSData *)obj encoding:NSUTF8StringEncoding];
        NSString *publicKey = [self.secretKey substringFromIndex:[kSAEncryptECCPrefix length]];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSString *result = [crypto performSelector:sel withObject:string withObject:publicKey];
#pragma clang diagnostic pop
        
        return result;
    }
    
    return nil;
}

@end
