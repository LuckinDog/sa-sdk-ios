//
// SAAutoTrackGestureConfig.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/1/27.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAAutoTrackGestureConfig.h"
#import "SAAutoTrackGestureItemInfo.h"

@interface SAAutoTrackGestureConfig ()

@property (nonatomic, strong) NSArray <SAAutoTrackGestureItemInfo *>*supportInfo;
@property (nonatomic, strong) NSArray <SAAutoTrackGestureItemInfo *>*forbiddenInfo;

@end

@implementation SAAutoTrackGestureConfig
#pragma mark - Life Cycle & Load Config
+ (instancetype)sharedInstance {
    static SAAutoTrackGestureConfig *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 从 mainBundle 加载配置文件, 允许用户重载配置文件
        sharedInstance = [[SAAutoTrackGestureConfig alloc] init];
        NSData *jsonData = [self loadConfigDataFromeBundle:[NSBundle mainBundle]];
        if (!jsonData) {
            // 从 SDK 中加载配置文件
            NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class] pathForResource:@"SensorsAnalyticsSDK.bundle" ofType:nil]];
            jsonData = [self loadConfigDataFromeBundle:sensorsBundle];
        }
        if (!jsonData) {
            return;
        }
        NSDictionary *config = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
        sharedInstance.supportInfo = [SAAutoTrackGestureItemInfo itemsFromInfo:config[@"support"][@"gesture"]];
        sharedInstance.forbiddenInfo = [SAAutoTrackGestureItemInfo itemsFromInfo:config[@"forbidden"][@"gesture"]];
    });
    return sharedInstance;
}

+ (NSData * _Nullable)loadConfigDataFromeBundle:(NSBundle *)bundle {
    NSString *jsonPath = [bundle pathForResource:@"sa_autotrack_gesture_config.json" ofType:nil];
    return [NSData dataWithContentsOfFile:jsonPath];
}

#pragma mark - Public
/// 获取支持采集的手势集合
- (NSArray <NSString *>*)supportGestures {
    return [SAAutoTrackGestureItemInfo typesFromItems:self.supportInfo];
}

/// 获取当前的 View 是不是配置文件中宿主 View 或 圈选 View
/// @param name View
- (SAGestureViewType)gestureViewTypeWithView:(NSString *)name {
    for (SAAutoTrackGestureItemInfo *item in self.supportInfo) {
        if ([item.hostView isEqualToString:name]) {
            return SAGestureViewTypeHost;
        }
        if ([item.visualView isEqualToString:name]) {
            return SAGestureViewTypeVisual;
        }
    }
    return SAGestureViewTypeNormal;
}

/// 通过宿主 View 获取圈选 View 类型集合
/// @param hostView 宿主 View
- (NSArray <NSString *>*)visualViewTypesWithHostView:(NSString *)hostView {
    NSMutableArray *result = [NSMutableArray array];
    for (SAAutoTrackGestureItemInfo *item in self.supportInfo) {
        if (![item.hostView isEqualToString:hostView]) continue;
        if (!item.visualView.length) continue;
        if ([result containsObject:item.visualView]) continue;
        [result addObject:item.visualView];
    }
    return [result copy];
}

/// 获取禁止采集手势的 View 集合
- (NSArray <NSString *>*)forbiddenViews {
    return [SAAutoTrackGestureItemInfo hostViewsFromItems:self.forbiddenInfo];
}

/// 校验是否是忽略页面浏览的控制器
/// @param controller 视图控制器
- (BOOL)isIgnoreViewController:(UIViewController *)controller {
    for (SAAutoTrackGestureItemInfo *item in self.supportInfo) {
        if ([item isIgnoreViewControllerWithController:controller]) {
            return YES;
        }
    }
    return NO;
}

/// 获取圈选 View 的 $element_type
/// @param view 圈选 View
- (NSString *_Nullable)elementTypeWithVisualView:(UIView *)view {
    for (SAAutoTrackGestureItemInfo *item in self.supportInfo) {
        NSString *type = [item elementTypeWithVisualView:view];
        if (type.length) {
            return type;
        }
    }
    return nil;
}

@end
