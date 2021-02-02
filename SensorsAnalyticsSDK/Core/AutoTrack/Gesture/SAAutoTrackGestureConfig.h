//
// SAAutoTrackGestureConfig.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAAutoTrackGestureConfig : NSObject

+ (NSArray <NSString *>*)supportGestures;

+ (void)viewTypeWithName:(NSString *)name completion:(void (^)(bool isHostView, bool isVisualView))completion;

+ (NSArray <NSString *>*)visualViewsWithHostView:(NSString *)hostView;

+ (NSArray <NSString *>*)forbiddenViews;

+ (BOOL)isIgnoreViewController:(UIViewController *)controller;

@end

NS_ASSUME_NONNULL_END
