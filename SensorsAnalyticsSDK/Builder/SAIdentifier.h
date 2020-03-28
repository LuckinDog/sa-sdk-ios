//
// SAIdentifier.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/2/17.
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAIdentifier : NSObject

/// 用户的登录 Id
@property (nonatomic, copy, readonly) NSString *loginId;

/// 匿名 Id（设备 Id）：IDFA -> IDFV -> UUID
@property (nonatomic, copy, readonly) NSString *anonymousId;

/// 唯一用户标识：loginId -> 设备 Id
@property (nonatomic, copy, readonly) NSString *distinctId;

/// Login 或 identify 操作前的 anonymousId
@property (nonatomic, copy, readonly) NSString *originalId;

/**
 初始化方法

 @param queue 一个全局队列
 @return 初始化对象
 */
- (instancetype)initWithGlobalQueue:(dispatch_queue_t)queue;

/**
 自定义匿名 Id（设备 Id）

 @param anonymousId 匿名 Id（设备 Id）
 */
- (void)identify:(NSString *)anonymousId;

/**
 重置匿名 Id
 */
- (void)resetAnonymousId;

/**
 通过登录接口设置 loginId

 @param loginId 新的 loginId
 */
- (BOOL)login:(NSString *)loginId completion:(nullable dispatch_block_t)completion;

/**
 通过退出登录接口删除本地的 loginId
 */
- (void)logout;

/**
 获取设备的 IDFA

 @return idfa
 */
+ (NSString *)idfa;

/**
 生成匿名 Id（设备 Id）：IDFA -> IDFV -> UUID

 @return 匿名 Id（设备 Id）
 */
+ (NSString *)generateUniqueHardwareId;

@end

NS_ASSUME_NONNULL_END
