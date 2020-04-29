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


@interface SAVisualizedWebPageInfo : NSObject

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
@property (nonatomic, copy, readonly) NSString *imageHashUpdateMessage;

/// 上次截图 hash
@property (nonatomic, copy, readonly) NSString *lastImageHash;

/// App 内嵌 H5 页面信息
@property (nonatomic, strong, readonly) SAVisualizedWebPageInfo *webPageInfo;

/// 弹框信息
/* 数据结构
 [{
    "title": "弹框标题",
    "message": "App SDK 与 Web SDK 没有进行打通，请联系贵方技术人员修正 Web SDK 的配置，详细信息请查看文档。",
    "link_text": "配置文档"
    "link_url": "https://manual.sensorsdata.cn/sa/latest/app-h5-1573913.html"
 }]
 */
@property (nonatomic, strong, readonly) NSMutableArray *alertInfos;

+ (instancetype)sharedInstance;

/// 重置解析配置
- (void)resetObjectSerializer;

/// 清除内嵌 H5 页面信息
- (void)cleanWebPageInfo;

/// 进入 web 页面
- (void)enterWebViewPageWithWebInfo:(SAVisualizedWebPageInfo *)webInfo;

/// 进入页面
- (void)enterViewController:(UIViewController *)viewController;

/// 强制刷新截图 hash 信息
- (void)refreshImageHashMessage:(NSString *)imageHash;

/// 重置最后截图 hash
- (void)resetLastImageHash:(NSString *)imageHash;

/// 添加弹框
- (void)registWebAlertInfos:(NSArray <NSDictionary *> *)infos;



@end
