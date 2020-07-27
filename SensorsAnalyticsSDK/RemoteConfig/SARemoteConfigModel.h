//
//  SARemoteConfigModel.h
//  SensorsAnalyticsSDK
//
// Created by wenquan on 2020/7/20.
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

#import <Foundation/Foundation.h>

// -1，表示不修改现有的 autoTrack 方式；0 代表禁用所有的 autoTrack；其他 1～15 为合法数据
static NSInteger kSAAutoTrackModeDefault = -1;
static NSInteger kSAAutoTrackModeDisabledAll = 0;
static NSInteger kSAAutoTrackModeEnabledAll = 15;

@interface SARemoteMainConfigModel : NSObject

@property (nonatomic, assign) BOOL disableSDK;
@property (nonatomic, assign) BOOL disableDebugMode;
@property (nonatomic, assign) NSInteger autoTrackMode; // -1, 0, 1~15

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)toDictionary;

@end

@interface SARemoteEventConfigModel : NSObject

@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSArray<NSString *> *blackList;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)toDictionary;

@end


@interface SARemoteConfigModel : NSObject

@property (nonatomic, copy) NSString *version;
@property (nonatomic, strong) SARemoteMainConfigModel *mainConfigModel;
@property (nonatomic, strong) SARemoteEventConfigModel *eventConfigModel;
@property (nonatomic, copy) NSString *localLibVersion; // 本地保存 SDK 版本号

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)toDictionary;

@end
