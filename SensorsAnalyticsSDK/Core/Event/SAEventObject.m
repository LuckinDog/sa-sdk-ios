//
// SAEventObject.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/6.
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

#import "SAEventObject.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAPresetProperty.h"
#import "SAFileStore.h"
#import "SAConstants+Private.h"
#import "SALog.h"
#import "SAModuleManager.h"
#import "SARemoteConfigManager.h"
#import "SACommonUtility.h"

static NSUInteger const SA_PROPERTY_LENGTH_LIMITATION = 8191;

@implementation SAEventObject

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    if (self = [super init]) {
        self.event = event;
        self.properties = [NSMutableDictionary dictionaryWithDictionary:properties];
        self.libObject = [[SAEventLibObject alloc] init];
        [self.libObject configDetailWithEvent:event properties:properties];
        
        self.currentSystemUpTime = NSProcessInfo.processInfo.systemUptime * 1000;
        self.timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
        
        self.loginId = SensorsAnalyticsSDK.sharedInstance.loginId;
        self.anonymousID = SensorsAnalyticsSDK.sharedInstance.anonymousId;
        self.track_id = @(arc4random());
    }
    return self;
}

- (BOOL)assertEachProperty:(BOOL(^)(NSString *key, NSString *value))eachProperty {
    NSDictionary *properties = [self.properties copy];
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
        self.properties = [NSMutableDictionary dictionaryWithDictionary:newProperties];
    }

    if (mutKeyArrayForValueIsNSNull) {
        [self.properties removeObjectForKey:mutKeyArrayForValueIsNSNull];
    }
    return YES;
}

- (BOOL)isCanTrack {
    if ([SARemoteConfigManager sharedInstance].isDisableSDK) {
        SALogDebug(@"【remote config】SDK is disabled");
        return NO;
    }
    
    if ([[SARemoteConfigManager sharedInstance] isBlackListContainsEvent:self.event]) {
        SALogDebug(@"【remote config】 %@ is ignored by remote config", self.event);
        return NO;
    }
    return YES;
}

- (BOOL)isValidProperties {
    return [self assertEachProperty:nil];
}

- (NSDictionary *)generateJSONObject {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[SA_EVENT_LIB] = [self.libObject generateJSONObject];
    return [properties copy];
}

- (BOOL)isValidNameForTrackEvent:(NSString *)eventName {
    if (eventName == nil || [eventName length] == 0) {
        NSString *errMsg = @"Event name should not be empty or nil";
        SALogError(@"%@", errMsg);
        SensorsAnalyticsDebugMode debugMode = SAModuleManager.sharedInstance.debugMode;
        if (debugMode != SensorsAnalyticsDebugOff) {
            [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
        }
        return NO;
    }
    if (![SensorsAnalyticsSDK.sharedInstance isValidName:eventName]) {
        NSString *errMsg = [NSString stringWithFormat:@"Event name[%@] not valid", eventName];
        SALogError(@"%@", errMsg);
        SensorsAnalyticsDebugMode debugMode = SAModuleManager.sharedInstance.debugMode;
        if (debugMode != SensorsAnalyticsDebugOff) {
            [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
        }
        return NO;
    }
    return YES;
}

@end

@implementation SASignUpEventObject

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    if (self = [super initWithEvent:event properties:properties]) {
        self.type = kSAEventTypeSignup;
    }
    return self;
}

- (NSDictionary *)generateJSONObject {
    [self addDeeplinkProperties];
    
    NSString *libMethod = [self.libObject obtainValidLibMethod:self.properties[SAEventPresetPropertyLibMethod]];
    self.properties[SAEventPresetPropertyLibMethod] = libMethod;
    self.libObject.method = libMethod;
    self.properties[SA_EVENT_LIB] = [self.libObject generateJSONObject];
    
    [self addPresetProperties];
    [self addSuperProperties];
    [self addDynamicProperties];
    
    return [self.properties copy];
}

@end

@implementation SACustomEventObject

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    if (self = [super initWithEvent:event properties:properties]) {
        if (![self isValidNameForTrackEvent:event]) {
            return nil;
        }
        [self addDeeplinkProperties];
        NSSet *presetEventNames = [NSSet setWithObjects:
                                   SA_EVENT_NAME_APP_START,
                                   SA_EVENT_NAME_APP_START_PASSIVELY ,
                                   SA_EVENT_NAME_APP_END,
                                   SA_EVENT_NAME_APP_VIEW_SCREEN,
                                   SA_EVENT_NAME_APP_CLICK,
                                   SA_EVENT_NAME_APP_SIGN_UP,
                                   SA_EVENT_NAME_APP_CRASHED,
                                   SA_EVENT_NAME_APP_REMOTE_CONFIG_CHANGED, nil];
        
        //事件校验，预置事件提醒
        if ([presetEventNames containsObject:event]) {
            SALogWarn(@"\n【event warning】\n %@ is a preset event name of us, it is recommended that you use a new one", event);
        }
        
        if (SensorsAnalyticsSDK.sharedInstance.configOptions.enableAutoAddChannelCallbackEvent) {
            // 后端匹配逻辑已经不需要 $channel_device_info 信息
            // 这里仍然添加此字段是为了解决服务端版本兼容问题
            self.properties[SA_EVENT_PROPERTY_CHANNEL_INFO] = @"1";

            BOOL isNotContains = ![self.trackChannelEventNames containsObject:event];
            self.properties[SA_EVENT_PROPERTY_CHANNEL_CALLBACK_EVENT] = @(isNotContains);
            if (isNotContains && event) {
                [self.trackChannelEventNames addObject:event];
                [self archiveTrackChannelEventNames];
            }
        }
        NSString *libMethod = [self.libObject obtainValidLibMethod:self.properties[SAEventPresetPropertyLibMethod]];
        self.properties[SAEventPresetPropertyLibMethod] = libMethod;
        self.libObject.method = libMethod;
        self.type = kSAEventTypeTrack;
    }
    return self;
}

- (void)archiveTrackChannelEventNames {
    [SAFileStore archiveWithFileName:SA_EVENT_PROPERTY_CHANNEL_INFO value:self.trackChannelEventNames];
}

@end

@implementation SAAutoTrackEventObject

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    if (self = [super initWithEvent:event properties:properties]) {
        if (![self isValidNameForTrackEvent:event]) {
            return nil;
        }
        [self addDeeplinkProperties];
        self.properties[SAEventPresetPropertyLibMethod] = kSALibMethodAuto;
        self.libObject.method = kSALibMethodAuto;
        self.type = kSAEventTypeTrack;
    }
    return self;
}

@end

@implementation SAPresetEventObject

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    if (self = [super initWithEvent:event properties:properties]) {
        if (![self isValidNameForTrackEvent:event]) {
            return nil;
        }
        [self addDeeplinkProperties];
        NSString *libMethod = [self.libObject obtainValidLibMethod:self.properties[SAEventPresetPropertyLibMethod]];
        self.properties[SAEventPresetPropertyLibMethod] = libMethod;
        self.libObject.method = libMethod;
        self.type = kSAEventTypeTrack;
    }
    return self;
}

@end

@implementation SAProfileEventObject

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    if (self = [super initWithEvent:event properties:properties]) {
        self.libObject.method = kSALibMethodCode;
    }
    return self;
}

@end

@implementation SAProfileIncrementEventObject

- (BOOL)isValidProperties {
    return [self assertEachProperty:^BOOL(NSString *key, NSString *value) {
        if (![value isKindOfClass:[NSNumber class]]) {
            NSString *errMsg = [NSString stringWithFormat:@"%@ profile_increment value must be NSNumber. got: %@ %@", self, [value class], value];
            SALogError(@"%@", errMsg);
            [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
            return NO;
        }
        return YES;
    }];
}

@end

@implementation SAProfileAppendEventObject

- (BOOL)isValidProperties {
    return [self assertEachProperty:^BOOL(NSString *key, NSString *value) {
        if (![value isKindOfClass:[NSSet class]] && ![value isKindOfClass:[NSArray class]]) {
            NSString *errMsg = [NSString stringWithFormat:@"%@ profile_append value must be NSSet、NSArray. got %@ %@", self, [value  class], value];
            SALogError(@"%@", errMsg);
            [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
            return NO;
        }
        return YES;
    }];
}

@end

@implementation SAH5EventObject

@end
