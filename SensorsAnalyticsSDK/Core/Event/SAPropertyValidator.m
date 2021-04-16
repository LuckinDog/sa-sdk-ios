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
    
    NSMutableDictionary *resultProperties = [properties copy];
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
        if (error) {
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
        if (error) {
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

+ (BOOL)assertProperties:(NSDictionary **)propertiesAddress
            eachProperty:(BOOL(^)(NSString *key, NSString *value))eachProperty {
    NSDictionary *properties = *propertiesAddress;
    NSMutableDictionary *newProperties = nil;
    NSMutableArray *mutKeyArrayForValueIsNSNull = nil;
    for (id __unused k in properties) {
        // key 必须是NSString
        if (![k isKindOfClass: [NSString class]]) {
            NSString *errMsg = @"Property Key should by NSString";
            SALogError(@"%@", errMsg);
            [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
            return NO;
        }

        // key的名称必须符合要求
        if (![SensorsAnalyticsSDK.sharedInstance isValidName: k]) {
            NSString *errMsg = [NSString stringWithFormat:@"property name[%@] is not valid", k];
            SALogError(@"%@", errMsg);
            [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
            return NO;
        }

        // value的类型检查
        id propertyValue = properties[k];
        if(![propertyValue isKindOfClass:[NSString class]] &&
           ![propertyValue isKindOfClass:[NSNumber class]] &&
           ![propertyValue isKindOfClass:[NSSet class]] &&
           ![propertyValue isKindOfClass:[NSArray class]] &&
           ![propertyValue isKindOfClass:[NSDate class]]) {
            NSString * errMsg = [NSString stringWithFormat:@"%@ property values must be NSString, NSNumber, NSSet, NSArray or NSDate. got: %@ %@", self, [propertyValue class], propertyValue];
            SALogError(@"%@", errMsg);
            [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];

            if ([propertyValue isKindOfClass:[NSNull class]]) {
                //NSNull 需要对数据做修复，remove 对应的 key
                if (!mutKeyArrayForValueIsNSNull) {
                    mutKeyArrayForValueIsNSNull = [NSMutableArray arrayWithObject:k];
                } else {
                    [mutKeyArrayForValueIsNSNull addObject:k];
                }
            } else {
                return NO;
            }
        }

        NSString *(^verifyString)(NSString *, NSMutableDictionary **, id *) = ^NSString *(NSString *string, NSMutableDictionary **dic, id *objects) {
            // NSSet、NSArray 类型的属性中，每个元素必须是 NSString 类型
            if (![string isKindOfClass:[NSString class]]) {
                NSString * errMsg = [NSString stringWithFormat:@"%@ value of NSSet、NSArray must be NSString. got: %@ %@", self, [string class], string];
                SALogError(@"%@", errMsg);
                [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
                return nil;
            }
            NSUInteger length = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            if (length > SA_PROPERTY_LENGTH_LIMITATION) {
                //截取再拼接 $ 末尾，替换原数据
                NSMutableString *newString = [NSMutableString stringWithString:[SACommonUtility subByteString:string byteLength:SA_PROPERTY_LENGTH_LIMITATION - 1]];
                [newString appendString:@"$"];
                if (*dic == nil) {
                    *dic = [NSMutableDictionary dictionaryWithDictionary:properties];
                }

                if (*objects == nil) {
                    *objects = [propertyValue mutableCopy];
                }
                return newString;
            }
            return string;
        };
        if ([propertyValue isKindOfClass:[NSSet class]]) {
            id object;
            NSMutableSet *newSetObject = nil;
            NSEnumerator *enumerator = [propertyValue objectEnumerator];
            while (object = [enumerator nextObject]) {
                NSString *string = verifyString(object, &newProperties, &newSetObject);
                if (string == nil) {
                    return NO;
                } else if (string != object) {
                    [newSetObject removeObject:object];
                    [newSetObject addObject:string];
                }
            }
            if (newSetObject) {
                [newProperties setObject:newSetObject forKey:k];
            }
        } else if ([propertyValue isKindOfClass:[NSArray class]]) {
            NSMutableArray *newArray = nil;
            for (NSInteger index = 0; index < [(NSArray *)propertyValue count]; index++) {
                id object = [propertyValue objectAtIndex:index];
                NSString *string = verifyString(object, &newProperties, &newArray);
                if (string == nil) {
                    return NO;
                } else if (string != object) {
                    [newArray replaceObjectAtIndex:index withObject:string];
                }
            }
            if (newArray) {
                [newProperties setObject:newArray forKey:k];
            }
        }

        // NSString 检查长度，但忽略部分属性
        if ([propertyValue isKindOfClass:[NSString class]]) {
            NSUInteger objLength = [((NSString *)propertyValue) lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            NSUInteger valueMaxLength = SA_PROPERTY_LENGTH_LIMITATION;
            if ([k isEqualToString:@"app_crashed_reason"]) {
                valueMaxLength = SA_PROPERTY_LENGTH_LIMITATION * 2;
            }
            if (objLength > valueMaxLength) {
                //截取再拼接 $ 末尾，替换原数据
                NSMutableString *newObject = [NSMutableString stringWithString:[SACommonUtility subByteString:propertyValue byteLength:valueMaxLength - 1]];
                [newObject appendString:@"$"];
                if (!newProperties) {
                    newProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
                }
                [newProperties setObject:newObject forKey:k];
            }
        }

        if (eachProperty) {
            if (!eachProperty(k, propertyValue)) {
                return NO;
            }
        }
    }
    //截取之后，修改原 properties
    if (newProperties) {
        *propertiesAddress = [NSDictionary dictionaryWithDictionary:newProperties];
    }

    if (mutKeyArrayForValueIsNSNull) {
        NSMutableDictionary *mutDict = [NSMutableDictionary dictionaryWithDictionary:*propertiesAddress];
        [mutDict removeObjectsForKeys:mutKeyArrayForValueIsNSNull];
        *propertiesAddress = [NSDictionary dictionaryWithDictionary:mutDict];
    }
    return YES;
}

@end
