//
// SADataEncryptBuilder.h
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


#import <Foundation/Foundation.h>
#import "SAConfigOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface SADataEncryptBuilder : NSObject

/**
 指定初始化方法设置密钥

 @param secretKey 密钥配置
 @return 配置对象
 */
- (instancetype)initWithSecretKey:(SASecretKey *)secretKey NS_DESIGNATED_INITIALIZER;

/// 禁用 init 初始化
- (instancetype)init NS_UNAVAILABLE;

/// 禁用 new 初始化
+ (instancetype)new NS_UNAVAILABLE;

/// 加密数据
- (nullable NSDictionary *)encryptionJSONObject:(id)obj;

@end

NS_ASSUME_NONNULL_END
