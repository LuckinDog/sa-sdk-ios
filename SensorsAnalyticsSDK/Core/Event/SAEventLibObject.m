//
// SAEventLibObject.m
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

#import "SAEventLibObject.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAPresetProperty.h"
#import "SAValidator.h"

@implementation SAEventLibObject

- (instancetype)init {
    self = [super init];
    if (self) {
        _lib = @"iOS";
        _method = kSALibMethodCode;
        _version = [SensorsAnalyticsSDK.sharedInstance libVersion];
        _appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        _detail = nil;
    }
    return self;
}

- (void)setMethod:(NSString *)method {
    if (![SAValidator isValidString:method]) {
        return;
    }
    _method = method;
}

#pragma mark - public
- (NSDictionary *)generateJSONObject {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[SAEventPresetPropertyLib] = self.lib;
    properties[SAEventPresetPropertyLibVersion] = self.version;
    properties[SAEventPresetPropertyAppVersion] = self.appVersion;
    properties[SAEventPresetPropertyLibMethod] = self.method;
    properties[SAEventPresetPropertyLibDetail] = self.detail;
    // TODO: 不 copy
    return [properties copy];
}

@end
