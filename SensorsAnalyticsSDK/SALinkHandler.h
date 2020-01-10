//
// SALinkHandler.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/1/6.
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

NS_ASSUME_NONNULL_BEGIN

@interface SALinkHandler : NSObject

/// DeepLink 中解析出来的参数是否需要保存到本地
@property (nonatomic, assign) BOOL enableSaveUtm;

/// 客户自定义的需要解析的来源渠道信息属性列表
@property (nonatomic, strong) NSArray *customSourceChanels;

/**
@abstract
 判断当前 URL 是否需要解析来源渠道信息

 @param url 被解析的 URL 对象
 @return 是否需要被解析
*/
- (BOOL)canHandleURL:(NSURL *)url;

/**
 @abstract
 解析当前 URL 中的来源渠道信息

 @param url 被解析的 URL 对象
*/
- (void)handleDeepLink:(NSURL *)url;

/**
 @abstract
 解析冷启动时 launchOptions 中的来源渠道信息

 @param launchOptions 冷启动时的 launchOptions
 */
- (void)handleLaunchOptions:(NSDictionary *)launchOptions;

/**
 @abstract
 最新的来源渠道信息

 @return latest utms 属性
 */
- (nullable NSDictionary *)latestUtmProperties;

/**
 @abstract
 当前 DeepLink 启动时的来源渠道信息

 @param reset 是否重置本次解析出来的来源渠道信息
 @return utms & custom utms 属性
 */
- (nullable NSDictionary *)utmProperties:(BOOL)reset;

@end

NS_ASSUME_NONNULL_END
