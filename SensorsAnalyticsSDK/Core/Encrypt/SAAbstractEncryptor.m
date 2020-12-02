//
// SAAbstractEncryptor.m
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

#import "SAAbstractEncryptor.h"
#import "SAConfigOptions.h"
#import "SAGzipUtility.h"
#import "SAJSONUtil.h"
#import "SAValidator.h"

@implementation SAAbstractEncryptor

#pragma mark - Life Cycle

- (instancetype)initWithSecretKey:(SASecretKey *)secretKey {
    self = [super init];
    if (self) {
        [self updateSecretKey:secretKey];
    }
    return self;
}

- (void)updateSecretKey:(SASecretKey *)secretKey {
    if (![SAValidator isValidString:secretKey.key] || [self.secretKey.key isEqualToString:secretKey.key]) {
        return;
    }
    
    self.secretKey = secretKey;
}

#pragma mark - Public

- (NSData *)gzipJSONObject:(id)obj {
    if (!obj) {
        return nil;
    }
    
    NSData *jsonData = [SAJSONUtil JSONSerializeObject:obj];
    NSString *encodingString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSData *encodingData = [encodingString dataUsingEncoding:NSUTF8StringEncoding];
    //使用 gzip 进行压缩
    return [SAGzipUtility gzipData:encodingData];
}

#pragma mark - SAEncryptorProtocol

- (nullable NSDictionary *)encryptJSONObject:(id)obj {
    // base implementation
    return nil;
}

@end
