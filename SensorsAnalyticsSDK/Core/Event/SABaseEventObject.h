//
// SABaseEventObject.h
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

#import <Foundation/Foundation.h>
#import "SAEventLibObject.h"
#import "SAEventBuildStrategy.h"
#import "SAPropertyValidator.h"

NS_ASSUME_NONNULL_BEGIN

@interface SABaseEventObject : NSObject <SAEventBuildStrategy>

/// 未登录时: 匿名 ID; 登录后: 登录 ID
@property (nonatomic, copy) NSString *distinctId;

/// 登录 ID
@property (nonatomic, copy) NSString *loginId;

/// 匿名 ID
@property (nonatomic, copy) NSString *anonymousId;

/// 事件名称
@property (nonatomic, copy) NSString *event;

/// 事件类型
@property (nonatomic, copy) NSString *type;

/// TODO: rename lib 信息
@property (nonatomic, strong) SAEventLibObject *lib;

/// 时间戳
@property (nonatomic, assign) UInt64 timeStamp;

/// 事件 id
@property (nonatomic, strong) NSNumber *trackId;

/// 项目
@property (nonatomic, copy) NSString *project;

/// token
@property (nonatomic, copy) NSString *token;

/// 事件属性
@property (nonatomic, strong) NSMutableDictionary *properties;

/// 用于统计事件时长
@property (nonatomic, assign) UInt64 currentSystemUpTime;

/// 属性校验器
@property (nonatomic, strong) SAPropertyValidator *propertiesValidator;

/// 生成最终的事件信息
- (NSDictionary *)generateJSONObject;

@end

NS_ASSUME_NONNULL_END
