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

NS_ASSUME_NONNULL_BEGIN

@interface SABaseEventObject : NSObject <SAEventBuildStrategy>

@property (nonatomic, copy) NSDictionary *properties;

@property (nonatomic, copy) NSString *type;

@property (nonatomic, strong) SAEventLibObject *libObject;

@property (nonatomic, assign) UInt64 currentSystemUpTime;

@property (nonatomic, assign) UInt64 timeStamp;

@property (nonatomic, strong) NSNumber *track_id;

@property (nonatomic, copy) NSString *project;

@property (nonatomic, copy) NSString *token;

@property (nonatomic, strong) NSMutableDictionary *resultProperties;

- (instancetype)initWithProperties:(NSDictionary *)properties;

/// 事件属性修正
/// @param destination 事件属性字典
- (void)correctionEventPropertiesWithDestination:(NSMutableDictionary *)destination;

/// 添加事件信息
/// @param destination 事件字典
- (void)addEventInfoToDestination:(NSMutableDictionary *)destination;

- (NSDictionary *)generateJSONObject;

- (BOOL)isValidProperties:(NSDictionary *_Nullable*_Nullable)properties;

@end

NS_ASSUME_NONNULL_END
