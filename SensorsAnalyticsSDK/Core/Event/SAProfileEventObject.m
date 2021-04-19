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

- (instancetype)initWithType:(NSString *)type {
    self = [super init];
    if (self) {
        self.type = type;
        self.libObject.method = kSALibMethodCode;
    }
    return self;
}

@end

@implementation SAProfileIncrementEventObject

- (instancetype)initWithType:(NSString *)type {
    self = [super initWithType:type];
    if (self) {
        self.propertiesValidator = [[SAProfileIncrementValidator alloc] init];
    }
    return self;
}

@end

@implementation SAProfileAppendEventObject

- (instancetype)initWithType:(NSString *)type {
    self = [super initWithType:type];
    if (self) {
        self.propertiesValidator = [[SAProfileAppendValidator alloc] init];
    }
    return self;
}

@end
