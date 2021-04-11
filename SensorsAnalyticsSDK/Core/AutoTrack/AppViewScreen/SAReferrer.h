//
// SAReferrer.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/4/10.
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

NS_ASSUME_NONNULL_BEGIN

@interface SAReferrer : NSObject

@property (nonatomic, assign, getter=isClearWhenAppEnd) BOOL clearWhenAppEnd;

@property (atomic, copy, nullable) NSDictionary *properties;
@property (atomic, copy, nullable) NSString *url;
@property (nonatomic, copy, nullable) NSString *title;


/// 事件属性中添加 $url 和 $referrer 字段
/// @param currentURL 当前的 url
/// @param eventProperties 事件属性
/// @param serialQueue 缓存 title 的串行队列
/// @param isEnableTitle 是否开启标题采集功能
- (NSDictionary *)propertiesWithURL:(NSString *)currentURL
                    eventProperties:(NSDictionary *)eventProperties
                        serialQueue:(dispatch_queue_t)serialQueue
                        enableTitle:(BOOL)isEnableTitle;

/// 清除 $referrer
- (void)clear;

@end

NS_ASSUME_NONNULL_END
