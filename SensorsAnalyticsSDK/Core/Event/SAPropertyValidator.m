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

static NSUInteger const SA_PROPERTY_LENGTH_LIMITATION = 8191;

@implementation SAPropertyValidator

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
