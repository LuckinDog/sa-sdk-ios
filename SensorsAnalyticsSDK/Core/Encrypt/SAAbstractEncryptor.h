//
// SAAbstractEncryptor.h
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

#import <Foundation/Foundation.h>

@class SASecretKey;

NS_ASSUME_NONNULL_BEGIN

@protocol SAEncryptorProtocol <NSObject>

@required

/// 加密 json 对象
/// @param obj 需要加密的 json 对象
/// @return 加密后的字典
- (nullable NSDictionary *)encryptJSONObject:(id)obj;

@end

@interface SAAbstractEncryptor : NSObject <SAEncryptorProtocol>

@property (nonatomic, strong) SASecretKey *secretKey;

/// 初始化加密器
/// @param secretKey 密钥
/// @return 加密器
- (instancetype)initWithSecretKey:(SASecretKey *)secretKey;

/// 使用 gzip 压缩 json 对象
/// @param obj json 对象
/// @return 压缩后的对象
- (NSData *)gzipJSONObject:(id)obj;

@end

NS_ASSUME_NONNULL_END
