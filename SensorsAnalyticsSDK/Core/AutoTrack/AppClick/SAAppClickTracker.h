//
// SAAppClickTracker.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/4/27.
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

#import <UIKit/UIKit.h>
#import "SAAppTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAAppClickTracker : SAAppTracker

/// 通过代码触发 UIView 的 $AppClick 事件
/// @param view UIView
/// @param properties 自定义属性
- (void)trackWithView:(UIView *)view properties:(NSDictionary<NSString *, id> * _Nullable)properties;

/// 忽略某一类型的 View
/// @param aClass View 对应的 Class
- (void)ignoreViewType:(Class)aClass;

/// 判断某个 View 类型是否被忽略
/// @param aClass Class View 对应的 Class
- (BOOL)isViewTypeIgnored:(Class)aClass;

@end

NS_ASSUME_NONNULL_END
