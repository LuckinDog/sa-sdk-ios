//
// SAEncryptorProtocol.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/12/12.
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

NS_ASSUME_NONNULL_BEGIN

@protocol SAEncryptorProtocol <NSObject>

/// 加密器的密钥（非对称加密时返回公钥）
@property (nullable, nonatomic, copy) id secretKey;

/// 初始化加密器
/// @param secretKey 初始化使用的密钥（非对称加密时为公钥）
/// @return 加密器
- (instancetype)initWithSecretKey:(id)secretKey;

/// 加密对象
/// @param obj 需要加密的对象
- (nullable NSString *)encryptObject:(id)obj;

@end

NS_ASSUME_NONNULL_END
