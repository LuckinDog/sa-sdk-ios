//
// SAPresetProperty.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/5/12.
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

#import "SAProperty.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAPresetProperty : SAProperty

@property (nonatomic, copy, readonly) NSDictionary *automaticProperties;

@property (nonatomic, copy, readonly) NSString *appVersion;
@property (nonatomic, copy, readonly) NSString *lib;
@property (nonatomic, copy, readonly) NSString *libVersion;

/**
获取首日的日期

*/
- (void)unarchiveFirstDay;

/**
是否为首日

@return 首日的判断结果
*/
- (BOOL)isFirstDay;

/**
获取预置属性

@return 当前的预置属性
*/
- (NSDictionary *)currentPresetProperties;

@end

NS_ASSUME_NONNULL_END
