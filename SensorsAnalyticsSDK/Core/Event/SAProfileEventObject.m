//
// SAProfileEventObject.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/13.
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

#import "SAProfileEventObject.h"
#import "SAConstants+Private.h"
#import "SAPropertyValidator.h"
#import "SAModuleManager.h"
#import "SALog.h"

@implementation SAProfileEventObject

- (instancetype)initWithProperties:(NSDictionary *)properties {
    if (self = [super initWithProperties:properties]) {
        self.libObject.method = kSALibMethodCode;
    }
    return self;
}

@end

@implementation SAProfileIncrementEventObject

- (BOOL)isValidProperties {
    NSDictionary *temp = [self.properties copy];
    BOOL isValid = [SAPropertyValidator assertProperties:&temp eachProperty:^BOOL(NSString * _Nonnull key, NSString * _Nonnull value) {
        if (![value isKindOfClass:[NSNumber class]]) {
            NSString *errMsg = [NSString stringWithFormat:@"%@ profile_increment value must be NSNumber. got: %@ %@", self, [value class], value];
            SALogError(@"%@", errMsg);
            [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
            return NO;
        }
        return YES;
    }];
    
    if (isValid) {
        self.properties = [temp mutableCopy];
        return YES;
    }
    
    SALogError(@"%@ failed to track event.", self);
    return NO;
}

@end

@implementation SAProfileAppendEventObject

- (BOOL)isValidProperties {
    NSDictionary *temp = [self.properties copy];
    BOOL isValid = [SAPropertyValidator assertProperties:&temp eachProperty:^BOOL(NSString * _Nonnull key, NSString * _Nonnull value) {
        if (![value isKindOfClass:[NSSet class]] && ![value isKindOfClass:[NSArray class]]) {
            NSString *errMsg = [NSString stringWithFormat:@"%@ profile_append value must be NSSet、NSArray. got %@ %@", self, [value  class], value];
            SALogError(@"%@", errMsg);
            [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
            return NO;
        }
        return YES;
    }];
    
    if (isValid) {
        self.properties = [temp mutableCopy];
        return YES;
    }
    
    SALogError(@"%@ failed to track event.", self);
    return NO;
}

@end
