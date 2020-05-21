//
// SAReadWriteLock.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/5/21.
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

@interface SAReadWriteLock : NSObject

/**
*  @abstract
*  初始化方法
*
*/
- (instancetype)init;

/**
*  @abstract
*  通过读写锁读取数据
*
*  @param block 读取操作
*
*/
- (void)read:(DISPATCH_NOESCAPE dispatch_block_t)block;

/**
*  @abstract
*  通过读写锁写入数据
*
*  @param block 写入操作
*
*/
- (void)write:(DISPATCH_NOESCAPE dispatch_block_t)block;

@end

NS_ASSUME_NONNULL_END
