//
// SARemoteConfigManager.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/11/1.
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
#import "SAConfigOptions.h"
#import "SANetwork.h"
#import "SARemoteConfigModel.h"
#import "SensorsAnalyticsSDK+Private.h"

NS_ASSUME_NONNULL_BEGIN

@class SARemoteConfigManagerOptions;

@protocol SARemoteConfigManagerProtocol <NSObject>

// TODO:wq 调用的地方添加对于是否实现协议的判断
@optional

/// 请求远程配置
- (void)requestRemoteConfig;

/// 删除远程配置请求
- (void)cancelRequestRemoteConfig;

/// 重试远程配置请求
/// @param isForceUpdate 是否强制请求最新的远程配置
- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate;

- (void)handleRemoteConfigURL:(NSURL *)url;

@end

@interface SARemoteConfigManagerOptions : NSObject

@property (nonatomic, strong) SAConfigOptions *configOptions; // SensorsAnalyticsSDK 初始化配置
@property (nonatomic, copy) NSString *currentLibVersion; // 当前 SDK 版本
@property (nonatomic, strong) SANetwork *network; // 网络相关类
@property (nonatomic, copy) BOOL (^encryptBuilderCreateResultBlock)(void); // 加密构造器创建结果的回调
@property (nonatomic, copy) void (^handleEncryptBlock)(NSDictionary *encryptConfig); // 处理加密的回调
@property (nonatomic, copy) void (^trackEventBlock)(NSString *event, NSDictionary *propertieDict); // 触发事件的回调
@property (nonatomic, copy) void (^triggerEffectBlock)(BOOL isDisableSDK, BOOL isDisableDebugMode); // 触发远程配置生效的回调

@end

@interface SARemoteConfigManager : NSObject <SARemoteConfigManagerProtocol>

@property (atomic, strong) SARemoteConfigModel *remoteConfigModel;
@property (nonatomic, strong) SARemoteConfigManagerOptions *managerOptions;
@property (nonatomic, assign, readonly) BOOL isDisableSDK; // 是否禁用 SDK
@property (nonatomic, assign, readonly) NSInteger autoTrackMode; // 控制 AutoTrack 采集方式（-1 表示不修改现有的 AutoTrack 方式；0 代表禁用所有的 AutoTrack；其他 1～15 为合法数据）
@property (nonatomic, copy, readonly) NSString *project;

- (instancetype)initWithManagerOptions:(SARemoteConfigManagerOptions *)managerOptions;

/// 配置本地远程配置模型
- (void)configLocalRemoteConfigModel;


- (NSDictionary<NSString *, id> *)extractRemoteConfig:(NSDictionary<NSString *, id> *)config;

- (NSDictionary<NSString *, id> *)extractEncryptConfig:(NSDictionary<NSString *, id> *)config;

- (nullable NSURLSessionTask *)functionalManagermentConfigWithOriginalVersion:(NSString *)originalVersion
                                                                latestVersion:(NSString *)latestVersion
                                                                   completion:(void(^)(BOOL success, NSDictionary<NSString *, id> *config))completion;

/// 是否在事件黑名单中
/// @param event 输入的事件名
- (BOOL)isBlackListContainsEvent:(NSString *)event;

- (void)trackAppRemoteConfigChanged:(NSDictionary<NSString *, id> *)remoteConfig;

- (void)enableRemoteConfigWithDictionary:(NSDictionary *)configDic;

@end

NS_ASSUME_NONNULL_END
