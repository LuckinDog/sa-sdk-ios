//
// SAProperty.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAProperty : NSObject

@property (nonatomic, strong, readonly) dispatch_queue_t queue;

/**
 初始化方法
 
 @param queue 一个全局队列
 @return 初始化对象
 */
- (instancetype)initWithQueue:(dispatch_queue_t)queue;

@end

NS_ASSUME_NONNULL_END
