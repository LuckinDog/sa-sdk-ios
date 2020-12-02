//
// SADataEncryptBuilder.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2019/7/23.
// Copyright © 2019-2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "SADataEncryptBuilder.h"
#import "SAAbstractEncryptor.h"
#import "SARSAEncryptor.h"
#import "SAECCEncryptor.h"
#import "SAConstants+Private.h"

@interface SADataEncryptBuilder()

@property (nonatomic, strong) SAAbstractEncryptor *encryptor;

@end

@implementation SADataEncryptBuilder

#pragma mark - Life Cycle

- (instancetype)initWithSecretKey:(SASecretKey *)secretKey {
    self = [super init];
    if (self) {
        [self initEncryptorWithSecretKey:secretKey];
    }
    return self;
}

- (void)initEncryptorWithSecretKey:(SASecretKey *)secretKey {
    if ([secretKey.key hasPrefix:kSAEncryptECCPrefix]) {
        _encryptor = [[SAECCEncryptor alloc] initWithSecretKey:secretKey];
    } else {
        _encryptor = [[SARSAEncryptor alloc] initWithSecretKey:secretKey];
    }
}

#pragma mark - Public Methods

- (nullable NSDictionary *)encryptionJSONObject:(id)obj {
    if ([self.encryptor respondsToSelector:@selector(encryptJSONObject:)]) {
        return [self.encryptor encryptJSONObject:obj];
    }
    return nil;
}

@end
