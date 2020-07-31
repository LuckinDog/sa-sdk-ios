//
// SARemoteConfigManager.h
// SensorsAnalyticsSDK
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <Foundation/Foundation.h>
#import "SARemoteConfigModel.h"
#import "SANetwork.h"
#import "SAConfigOptions.h"
#import "SensorsAnalyticsSDK+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface SARemoteConfigManagerOptions : NSObject

/// SensorsAnalyticsSDK 初始化配置
@property (nonatomic, strong) SAConfigOptions *configOptions;

/// 当前 SDK 版本
@property (nonatomic, copy) NSString *currentLibVersion;

/// 网络相关类
@property (nonatomic, strong) SANetwork *network;

/// 加密构造器创建结果
@property (nonatomic, copy) BOOL (^encryptBuilderCreateResultBlock)(void);

/// 禁用 debugMode 的回调
@property (nonatomic, copy) void (^disableDebugModeBlock)(void);

/// 处理密钥的回调
@property (nonatomic, copy) void (^handleSecretKeyBlock)(NSDictionary *configDict);

/// 触发事件的回调
@property (nonatomic, copy) void (^trackEventBlock)(NSString *event, NSDictionary *propertieDict);

@end


@interface SARemoteConfigManager : NSObject

@property (nonatomic, assign, readonly) BOOL isDisableSDK; // 是否禁用 SDK
@property (nonatomic, assign, readonly) NSInteger autoTrackMode; // 控制 AutoTrack 采集方式（-1 表示不修改现有的 AutoTrack 方式；0 代表禁用所有的 AutoTrack；其他 1～15 为合法数据）


/// 初始化远程配置管理类
/// @param managerOptions 管理模型
+ (void)startWithRemoteConfigManagerOptions:(SARemoteConfigManagerOptions *)managerOptions;

/// 获取管理类的实例
+ (SARemoteConfigManager *_Nullable)sharedInstance;

/// 创建本地远程配置模型
- (void)createLocalRemoteConfigModel;

/// 请求远程配置
- (void)requestRemoteConfig;

/// 删除远程配置请求
- (void)cancelRequestRemoteConfig;

/// 重试远程配置请求
/// @param isForceUpdate 是否强制请求最新的远程配置
- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate;

/// 是否在事件黑名单中
/// @param event 输入的事件名
- (BOOL)isBlackListContainsEvent:(NSString *)event;

@end

NS_ASSUME_NONNULL_END
