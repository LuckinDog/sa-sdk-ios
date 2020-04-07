//
// SAVisualizedObjectSerializerManger.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/4/7.
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

#import "SAVisualizedObjectSerializerManger.h"

@interface SAVisualizedObjectSerializerManger()

@end

@implementation SAVisualizedObjectSerializerManger

+ (instancetype)sharedInstance {
    static SAVisualizedObjectSerializerManger *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SAVisualizedObjectSerializerManger alloc] init];
    });
    return manager;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        [self initializeObjectSerializer];
    }
    return self;
}

- (void)initializeObjectSerializer {
    _imageHashUpdateMessage = nil;
    _isContainWebView = NO;
}

/// 重置解析配置
- (void)resetObjectSerializer {
    [self initializeObjectSerializer];
}

@end
