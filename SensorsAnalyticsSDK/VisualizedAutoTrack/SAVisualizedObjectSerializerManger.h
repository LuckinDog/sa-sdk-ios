//
// SAVisualizedObjectSerializerManger.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/4/23.
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
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAVisualizedJSConfig : NSObject

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *title;

@end


/// 可视化全埋点 viewTree 外层数据管理
@interface SAVisualizedObjectSerializerManger : NSObject

/// 是否包含 webview
@property (nonatomic, assign, readonly) BOOL isContainWebView;

/// 当前页面
@property (nonatomic, strong, readonly) UIViewController *currentViewController;

/// 截图 hash 更新信息，如果存在，则添加到 image_hash 后缀
@property (nonatomic, copy) NSString *imageHashUpdateMessage;

@property (nonatomic, strong) SAVisualizedJSConfig *jsConfig;

+ (instancetype)sharedInstance;

/// 重置解析配置
- (void)resetObjectSerializer;

/// 进入 web 页面
- (void)enterWebViewPage;

/// 进入页面
- (void)enterViewController:(UIViewController *)viewController;
@end

NS_ASSUME_NONNULL_END
