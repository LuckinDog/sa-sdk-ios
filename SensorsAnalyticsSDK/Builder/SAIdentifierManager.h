//
// SAIdentifierManager.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/3/25.
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

@interface SAIdentifierManager : NSObject

/**
 * @property
 *
 * @abstract
 * 用户唯一用户标识
*/
@property (nonatomic, copy, readonly) NSString *distinctId;

/**
 * @property
 *
 * @abstract
 * 用户登录唯一标识符
*/
@property (nonatomic, copy, readonly) NSString *loginId;

/**
 * @property
 *
 * @abstract
 * 用户设备唯一标识符
*/
@property (nonatomic, copy, readonly) NSString *anonymousId;

/**
 * @property
 *
 * @abstract
 * 用户原始标识
 *
 * @discussion
 * 重置后的 originalId 为当前的 anonymousId
*/
@property (nonatomic, copy, readonly) NSString *originalId;

/**
 * @abstract
 * 设置并归档 loginId
*/
- (void)archiveLoginId:(nullable NSString *)loginId;

/**
 * @abstract
 * 设置并归档 anonymousId
*/
- (void)archiveAnonymousId:(NSString *)anonymousId;

/**
 * @abstract
 * 重置 originalId
 *
 * @discussion
 * 重置后的 originalId 为当前的 anonymousId
*/
- (void)resetOriginalId;

/**
 * @abstract
 * 重置 anonymousId
*/
- (void)resetAnonymousId;

/**
 * @abstract
 * 硬件唯一标识符
 *
 * @discussion
 * 获取优先级为 IDFA > IDFV > UUID
*/
- (NSString *)uniqueHardwareId;

@end

NS_ASSUME_NONNULL_END
