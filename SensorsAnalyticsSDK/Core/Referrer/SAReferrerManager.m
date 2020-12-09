//
// SAReferrerManager.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/12/9.
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

#import "SAReferrerManager.h"
#import "SAConstants+Private.h"

@interface SAReferrerManager ()

@property (nonatomic, copy) NSString *currentTitle;
@property (nonatomic, copy, readwrite) NSString *referrerTitle;

@end

@implementation SAReferrerManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SAReferrerManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[SAReferrerManager alloc] init];
    });
    return manager;
}

- (void)getReferrerTitle:(NSDictionary *)properties {
    NSString *title = properties[SA_EVENT_PROPERTY_TITLE];
    _referrerTitle = _currentTitle;
    _currentTitle = title;
}

@end
