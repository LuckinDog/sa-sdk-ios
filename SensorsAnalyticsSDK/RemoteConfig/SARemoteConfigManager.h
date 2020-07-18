//
// SARemoteConfigManager.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/7/16.
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

#import <Foundation/Foundation.h>
#import "SARemoteConfigModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SARemoteConfigManager : NSObject

@property (nonatomic, strong, readonly) SARemoteMainConfigModel *mainConfigModel;
@property (nonatomic, strong, readonly) SARemoteEventConfigModel *eventConfigModel;

/// 获取远程配置管理类的实例
+ (instancetype)sharedInstance;

/// 创建本地远程配置模型
- (void)createLocalRemoteConfigModel;

/// 尝试请求远程配置
- (void)shouldRequestRemoteConfig;

/// 删除远程配置请求
- (void)cancelRequestRemoteConfig;

/// 重试远程配置请求
- (void)retryRequestRemoteConfig;

@end

NS_ASSUME_NONNULL_END
