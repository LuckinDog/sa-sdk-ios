//
// SAPropertyValidator.m
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAPropertyValidator.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SACommonUtility.h"
#import "SADateFormatter.h"

#define SAPropertyError(errorCode, desc) [NSError errorWithDomain:@"SensorsAnalyticsErrorDomain" code:errorCode userInfo:@{NSLocalizedDescriptionKey: desc}]

static NSUInteger const kSAPropertyLengthLimitation = 8191;

@implementation NSString (SAProperty)

- (void)sensorsdata_isValidPropertyKeyWithError:(NSError *__autoreleasing  _Nullable *)error {
    if (![SensorsAnalyticsSDK.sharedInstance isValidName: self]) {
        *error = SAPropertyError(10001, ([NSString stringWithFormat:@"property name[%@] is not valid", self]));
    }
}

- (id)sensorsdata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    NSInteger maxLength = kSAPropertyLengthLimitation;
    if ([key isEqualToString:@"app_crashed_reason"]) {
        maxLength = kSAPropertyLengthLimitation * 2;
    }
    NSUInteger length = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (length > maxLength) {
        //截取再拼接 $ 末尾，替换原数据
        NSMutableString *newString = [NSMutableString stringWithString:[SACommonUtility subByteString:self byteLength:maxLength - 1]];
        [newString appendString:@"$"];
        return [newString copy];
    }
    return self;
}

@end

@implementation NSNumber (SAProperty)

- (id)sensorsdata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    return self;
}

@end

@implementation NSDate (SAProperty)

- (id)sensorsdata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    return self;
}

@end

@implementation NSSet (SAProperty)

- (id)sensorsdata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    NSMutableSet *result = [NSMutableSet set];
    for (id element in self) {
        if (![element isKindOfClass:NSString.class]) {
            NSString * errMsg = [NSString stringWithFormat:@"%@ value of NSSet, NSArray must be NSString. got: %@ %@", self, [element class], element];
            *error = SAPropertyError(10004, errMsg);
            return nil;
        }
        id sensorsValue = [(id <SAPropertyValueProtocol>)element sensorsdata_propertyValueWithKey:key error:error];
        [result addObject:sensorsValue];
    }
    return [result copy];
}

@end

@implementation NSArray (SAProperty)

- (id)sensorsdata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    NSMutableArray *result = [NSMutableArray array];
    for (id element in self) {
        if (![element isKindOfClass:NSString.class]) {
            NSString * errMsg = [NSString stringWithFormat:@"%@ value of NSSet, NSArray must be NSString. got: %@ %@", self, [element class], element];
            *error = SAPropertyError(10004, errMsg);
            return nil;
        }
        id sensorsValue = [(id <SAPropertyValueProtocol>)element sensorsdata_propertyValueWithKey:key error:error];
        [result addObject:sensorsValue];
    }
    return [result copy];
}

@end

@implementation NSNull (SAProperty)

- (id)sensorsdata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    return nil;
}

@end

@implementation SAPropertyValidator

+ (NSDictionary *)validProperties:(NSDictionary *)properties error:(NSError **)error {
    if (![properties isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (id key in properties) {
        // key 校验
        if (![key conformsToProtocol:@protocol(SAPropertyKeyProtocol)]) {
            *error = SAPropertyError(10001, ([NSString stringWithFormat:@"Property Key should by %@", NSStringFromClass([key class])]));
            return nil;
        }
        
        [(id <SAPropertyKeyProtocol>)key sensorsdata_isValidPropertyKeyWithError:error];
        if (*error) {
            return nil;
        }
        
        // value 校验
        id value = properties[key];
        if (![value conformsToProtocol:@protocol(SAPropertyValueProtocol)]) {
            NSString *errMsg = [NSString stringWithFormat:@"%@ property values must be NSString, NSNumber, NSSet, NSArray or NSDate. got: %@ %@", self, [value class], value];
            *error = SAPropertyError(10003, errMsg);
            return nil;
        }
        
        // value 转换
        id sensorsValue = [(id <SAPropertyValueProtocol>)value sensorsdata_propertyValueWithKey:key error:error];
        if (*error) {
            return nil;
        }
        
        if (sensorsValue) {
            result[key] = sensorsValue;
        }
    }
    return [result copy];
}

- (NSDictionary *)validProperties:(NSDictionary *)properties error:(NSError **)error {
    return [[self class] validProperties:properties error:error];
}

@end

@implementation SAProfileAppendValidator

+ (NSDictionary *)validProperties:(NSDictionary *)properties error:(NSError **)error {
    if (![properties isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (id key in properties) {
        // key 校验
        if (![key conformsToProtocol:@protocol(SAPropertyKeyProtocol)]) {
            *error = SAPropertyError(10001, ([NSString stringWithFormat:@"Property Key should by %@", NSStringFromClass([key class])]));
            return nil;
        }
        
        [(id <SAPropertyKeyProtocol>)key sensorsdata_isValidPropertyKeyWithError:error];
        if (*error) {
            return nil;
        }
        
        // value 校验
        id value = properties[key];
        if (![value isKindOfClass:[NSArray class]] &&
            ![value isKindOfClass:[NSSet class]]) {
            NSString *errMsg = [NSString stringWithFormat:@"%@ profile_append value must be NSSet, NSArray. got %@ %@", self, [value  class], value];
            *error = SAPropertyError(10003, errMsg);
            return nil;
        }
        
        // value 转换
        id sensorsValue = [(id <SAPropertyValueProtocol>)value sensorsdata_propertyValueWithKey:key error:error];
        if (*error) {
            return nil;
        }
        
        if (sensorsValue) {
            result[key] = sensorsValue;
        }
    }
    return [result copy];
}

@end

@implementation SAProfileIncrementValidator

+ (NSDictionary *)validProperties:(NSDictionary *)properties error:(NSError **)error {
    if (![properties isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (id key in properties) {
        // key 校验
        if (![key conformsToProtocol:@protocol(SAPropertyKeyProtocol)]) {
            *error = SAPropertyError(10001, ([NSString stringWithFormat:@"Property Key should by %@", NSStringFromClass([key class])]));
            return nil;
        }
        
        [(id <SAPropertyKeyProtocol>)key sensorsdata_isValidPropertyKeyWithError:error];
        if (*error) {
            return nil;
        }
        
        // value 校验
        id value = properties[key];
        if (![value isKindOfClass:[NSNumber class]]) {
            NSString *errMsg = [NSString stringWithFormat:@"%@ profile_increment value must be NSNumber. got: %@ %@", self, [value class], value];
            *error = SAPropertyError(10003, errMsg);
            return nil;
        }
        
        result[key] = value;
    }
    return [result copy];
}

@end
