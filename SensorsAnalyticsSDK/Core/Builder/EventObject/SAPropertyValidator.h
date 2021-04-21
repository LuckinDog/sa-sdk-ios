//
// SAPropertyValidator.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/12.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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

#define SAPropertyError(errorCode, fromat, ...) \
    [NSError errorWithDomain:@"SensorsAnalyticsErrorDomain" \
                        code:errorCode \
                    userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:fromat,##__VA_ARGS__]}] \

@protocol SAPropertyKeyProtocol <NSObject>

- (void)sensorsdata_isValidPropertyKeyWithError:(NSError **)error;

@end

@protocol SAPropertyValueProtocol <NSObject>

- (id _Nullable)sensorsdata_propertyValueWithKey:(NSString *)key error:(NSError **)error;

@end

@interface NSString (SAProperty)<SAPropertyKeyProtocol, SAPropertyValueProtocol>
@end

@interface NSNumber (SAProperty)<SAPropertyValueProtocol>
@end

@interface NSDate (SAProperty)<SAPropertyValueProtocol>
@end

@interface NSSet (SAProperty)<SAPropertyValueProtocol>
@end

@interface NSArray (SAProperty)<SAPropertyValueProtocol>
@end

@interface NSNull (SAProperty)<SAPropertyValueProtocol>
@end

@interface SAPropertyValidator : NSObject

/// 属性校验
/// @param properties 属性
/// @param error 错误信息
+ (NSMutableDictionary *)validProperties:(NSDictionary *)properties error:(NSError **)error;

- (NSMutableDictionary *)validProperties:(NSDictionary *)properties error:(NSError **)error;

@end

@interface SAProfileAppendValidator : SAPropertyValidator

/// profile_append 中属性校验: value 必须为集合类型
/// @param properties 属性
/// @param error 错误信息
+ (NSMutableDictionary *)validProperties:(NSDictionary *)properties error:(NSError **)error;

@end

@interface SAProfileIncrementValidator : SAPropertyValidator

/// profile_increment 中属性校验: value 必须为 NSNumber 类型
/// @param properties 属性
/// @param error 错误信息
+ (NSMutableDictionary *)validProperties:(NSDictionary *)properties error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
