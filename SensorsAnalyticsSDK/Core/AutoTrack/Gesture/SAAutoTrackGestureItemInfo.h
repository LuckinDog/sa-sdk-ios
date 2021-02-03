//
// SAAutoTrackGestureItemInfo.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/1/28.
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
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAAutoTrackGestureItemInfo : NSObject

/// 手势类型
@property (nonatomic, copy) NSString *type;

/// 采集私有手势时, 手势所在的宿主 View 类型
@property (nonatomic, copy) NSString *hostView;

/// 采集私有手势时, $element_type 类型
@property (nonatomic, copy) NSString *elementType;

/// 忽略的页面; 弹框, 菜单等不能作为单独的页面
@property (nonatomic, strong) NSDictionary *ignoreViewController;

/// 采集私有手势时, 通过宿主 View 查询可圈选的 View 类型
@property (nonatomic, copy) NSString *visualView;

/// 构造方法
/// @param config 通过 NSDictionary 构造一个 item
- (instancetype)initWithConfig:(NSDictionary *)config;

/// 根据圈选 View 获取 $element_type 类型
/// @param visualView 圈选 View
- (NSString *_Nullable)elementTypeWithVisualView:(UIView *)visualView;

/// 采集 screen_name 时, 是不是需要忽略的视图控制器
/// @param controller 视图控制器
- (BOOL)isIgnoreViewControllerWithController:(UIViewController *)controller;

/// 通过将数组中的 NSDictionary 解析为 items 数组
/// @param info 带解析的字典
+ (NSArray <SAAutoTrackGestureItemInfo *>*)itemsFromInfo:(NSArray <NSDictionary *>*)info;

/// 从 items 中获取手势类型 type, 组成集合
/// @param items 带提取的 items
+ (NSArray <NSString *>*)typesFromItems:(NSArray <SAAutoTrackGestureItemInfo *>*)items;

/// 从 items 中获取宿主 view, 组成集合
/// @param items 带提取的 items
+ (NSArray <NSString *>*)hostViewsFromItems:(NSArray <SAAutoTrackGestureItemInfo *>*)items;

@end

NS_ASSUME_NONNULL_END
