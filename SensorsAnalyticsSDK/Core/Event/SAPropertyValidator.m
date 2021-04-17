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
#import "SAModuleManager.h"
#import "SACommonUtility.h"
#import "SALog.h"

#define SAPropertyError(errorCode, desc) [NSError errorWithDomain:@"SensorsAnalyticsErrorDomain" code:errorCode userInfo:@{NSLocalizedDescriptionKey: desc}]

static NSUInteger const SA_PROPERTY_LENGTH_LIMITATION = 8191;

@implementation SAPropertyValidator

+ (NSDictionary *)validProperties:(NSDictionary *)properties error:(NSError **)error {
    return [self validProperties:properties eachProperty:nil error:error];
}

+ (NSDictionary *)validProfileAppendProperties:(NSDictionary *)properties error:(NSError **)error {
    NSError *innerError = nil;
    __block NSString *innerKey;
    __block NSString *innervalue;
    NSDictionary *dic = [self validProperties:properties eachProperty:^BOOL(NSString *key, NSString *value) {
        innerKey = key;
        innervalue = value;
        return ([value isKindOfClass:NSArray.class] || [value isKindOfClass:NSSet.class]);
    } error:&innerError];
    
    if (innerError) {
        if (innerError.code == 10009) {
            NSString *errMsg = [NSString stringWithFormat:@"%@ profile_append value must be NSSet、NSArray. got %@ %@", self, [innervalue  class], innervalue];
            *error = SAPropertyError(innerError.code, errMsg);
        }
        *error = innerError;
        return nil;
    }
    return dic;
}

+ (NSDictionary *)validProfileIncrementProperties:(NSDictionary *)properties error:(NSError **)error {
    NSError *innerError = nil;
    __block NSString *innerKey;
    __block NSString *innervalue;
    NSDictionary *dic = [self validProperties:properties eachProperty:^BOOL(NSString *key, NSString *value) {
        innerKey = key;
        innervalue = value;
        return [value isKindOfClass:NSNumber.class];
    } error:&innerError];
    
    if (innerError) {
        if (innerError.code == 10009) {
            NSString *errMsg = [NSString stringWithFormat:@"%@ profile_increment value must be NSNumber. got: %@ %@", self, [innervalue class], innervalue];
            *error = SAPropertyError(innerError.code, errMsg);
        }
        *error = innerError;
        return nil;
    }
    return dic;
}

+ (NSDictionary *)validProperties:(NSDictionary *)properties eachProperty:(BOOL(^)(NSString *key, NSString *value))eachProperty error:(NSError **)error {
    
    NSMutableDictionary *resultProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
    NSMutableArray *mutKeyArrayForValueIsNSNull = [NSMutableArray array];
    NSMutableArray *mutKeyArrayForValueIsNSString = [NSMutableArray array];
    NSMutableArray *mutKeyArrayForValueIsNSSet = [NSMutableArray array];
    NSMutableArray *mutKeyArrayForValueIsNSArray = [NSMutableArray array];
    
    for (id key in properties.allKeys) {
        // key 校验
        if (![key isKindOfClass:NSString.class]) {
            *error = SAPropertyError(10001, @"Property Key should by NSString");
            return nil;
        }
        if (![SensorsAnalyticsSDK.sharedInstance isValidName: key]) {
            *error = SAPropertyError(10002, ([NSString stringWithFormat:@"property name[%@] is not valid", key]));
            return nil;
        }
        
        // value 校验
        id value = properties[key];
        if (eachProperty) {
            BOOL isValid = eachProperty(key, value);
            if (!isValid) {
                *error = SAPropertyError(10009, ([NSString stringWithFormat:@"property name[%@] value[%@] is not valid", key, value]));
                return nil;
            }
        }
        
        if ([value isKindOfClass:NSNull.class]) {
            [mutKeyArrayForValueIsNSNull addObject:key];
            continue;
        }
        if ([value isKindOfClass:NSString.class]) {
            [mutKeyArrayForValueIsNSString addObject:key];
            continue;
        }
        if ([value isKindOfClass:NSSet.class]) {
            [mutKeyArrayForValueIsNSSet addObject:key];
            continue;
        }
        if ([value isKindOfClass:NSArray.class]) {
            [mutKeyArrayForValueIsNSArray addObject:key];
            continue;
        }
        if ([value isKindOfClass:NSNumber.class] ||
            [value isKindOfClass:NSDate.class]) {
            continue;
        }
        
        NSString *errMsg = [NSString stringWithFormat:@"%@ property values must be NSString, NSNumber, NSSet, NSArray or NSDate. got: %@ %@", self, [value class], value];
        *error = SAPropertyError(10003, errMsg);
        return nil;
    }
    
    // 移除 value = NSNULL 的键值对
    if (mutKeyArrayForValueIsNSNull.count > 0) {
        [resultProperties removeObjectsForKeys:mutKeyArrayForValueIsNSNull];
    }
    
    // 校验 NSString
    if (mutKeyArrayForValueIsNSString.count > 0) {
        for (NSString *key in mutKeyArrayForValueIsNSString) {
            NSString *string = resultProperties[key];
            NSUInteger maxLength = SA_PROPERTY_LENGTH_LIMITATION;
            if ([key isEqualToString:@"app_crashed_reason"]) {
                maxLength = SA_PROPERTY_LENGTH_LIMITATION * 2;
            }
            NSString *newString = [self validStringElement:string maxLength:maxLength error:nil];
            resultProperties[key] = newString;
        }
    }
    
    // 校验 NSArray 集合元素: 必须为 String 类型
    if (mutKeyArrayForValueIsNSArray.count > 0) {
        for (NSString *key in mutKeyArrayForValueIsNSArray) {
            NSArray *array = resultProperties[key];
            NSArray *newArray = [self validArrayElement:array error:error];
            if (*error) {
                return nil;
            }
            resultProperties[key] = newArray;
        }
    }
    
    // 校验 NSSet 集合元素: 必须为 String 类型
    if (mutKeyArrayForValueIsNSSet.count > 0) {
        for (NSString *key in mutKeyArrayForValueIsNSSet) {
            NSSet *set = resultProperties[key];
            NSSet *newSet = [self validSetElement:set error:error];
            if (*error) {
                return nil;
            }
            resultProperties[key] = newSet;
        }
    }
    return [resultProperties copy];
}

+ (NSArray <NSString *>*)validArrayElement:(NSArray *)array error:(NSError **)error {
    NSMutableArray <NSString *>*newArray = [NSMutableArray array];
    for (NSInteger index = 0; index < array.count; index++) {
        id element = [array objectAtIndex:index];
         NSString *newElement = [self validStringElement:element maxLength:SA_PROPERTY_LENGTH_LIMITATION error:error];
        if (*error) {
            return @[];
        }
        [newArray addObject:newElement];
    }
    return [newArray copy];
}

+ (NSSet <NSString *>*)validSetElement:(NSSet *)set error:(NSError **)error {
    NSMutableSet <NSString *>*newSet = [NSMutableSet set];
    for (id element in set) {
         NSString *newElement = [self validStringElement:element maxLength:SA_PROPERTY_LENGTH_LIMITATION error:error];
        if (*error) {
            return [NSSet set];
        }
        [newSet addObject:newElement];
    }
    return [newSet copy];
}

+ (NSString *)validStringElement:(id)element maxLength:(NSInteger)maxLength error:(NSError **)error {
    if (![element isKindOfClass:NSString.class]) {
        NSString *errMsg = [NSString stringWithFormat:@"%@ property values must be NSString, NSNumber, NSSet, NSArray or NSDate. got: %@ %@", self, [element class], element];
        *error = SAPropertyError(10004, errMsg);
        return nil;
    }
    NSUInteger length = [element lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (length > maxLength) {
        //截取再拼接 $ 末尾，替换原数据
        NSMutableString *newString = [NSMutableString stringWithString:[SACommonUtility subByteString:element byteLength:maxLength - 1]];
        [newString appendString:@"$"];
        return [newString copy];
    }
    return [element copy];
}

@end
