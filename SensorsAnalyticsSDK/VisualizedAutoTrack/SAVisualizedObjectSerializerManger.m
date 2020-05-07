//
// SAVisualizedObjectSerializerManger.m
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAVisualizedObjectSerializerManger.h"
#import "SAJSONUtil.h"


@implementation SAVisualizedWebPageInfo

@end


@interface SAVisualizedObjectSerializerManger()

/// 是否包含 webview
@property (nonatomic, assign, readwrite) BOOL isContainWebView;

/// App 内嵌 H5 页面信息
@property (nonatomic, strong, readwrite) SAVisualizedWebPageInfo *webPageInfo;

/// 截图 hash 更新信息，如果存在，则添加到 image_hash 后缀
@property (nonatomic, copy, readwrite) NSString *imageHashUpdateMessage;

/// 上次截图 hash
@property (nonatomic, copy, readwrite) NSString *lastImageHash;

/// 保存不同 controller 可点击元素个数
@property (nonatomic, copy) NSMapTable <UIViewController *, NSNumber *> *viewControllerFindCountData;

/// 弹框信息
@property (nonatomic, strong, readwrite) NSMutableArray *alertInfos;
@end

@implementation SAVisualizedObjectSerializerManger

+ (instancetype)sharedInstance {
    static SAVisualizedObjectSerializerManger *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SAVisualizedObjectSerializerManger alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initializeObjectSerializer];
    }
    return self;
}

- (void)initializeObjectSerializer {
    _viewControllerFindCountData = [NSMapTable weakToStrongObjectsMapTable];
    _alertInfos = [NSMutableArray array];
    [self resetObjectSerializer];
}

/// 重置解析配置
- (void)resetObjectSerializer {
    self.isContainWebView = NO;
    [self.viewControllerFindCountData removeAllObjects];

    self.webPageInfo = nil;
    [self.alertInfos removeAllObjects];
}

- (void)enterWebViewPageWithWebInfo:(SAVisualizedWebPageInfo *)webInfo; {
    self.isContainWebView = YES;
    if (webInfo) {
        self.webPageInfo = webInfo;
    }
}

/// 进入页面
- (void)enterViewController:(UIViewController *)viewController {
    NSNumber *countNumber = [self.viewControllerFindCountData objectForKey:viewController];
    if (countNumber) {
        NSInteger countValue = [countNumber integerValue];
        [self.viewControllerFindCountData setObject:@(countValue + 1) forKey:viewController];
    } else {
        [self.viewControllerFindCountData setObject:@(1) forKey:viewController];
    }
}

- (void)refreshImageHashMessage:(NSString *)imageHash {
    self.imageHashUpdateMessage = imageHash;
}


- (void)resetLastImageHash:(NSString *)imageHash {
    self.lastImageHash = imageHash;
    self.imageHashUpdateMessage = nil;
}
- (UIViewController *)currentViewController {
    NSArray <UIViewController *>*allViewControllers = NSAllMapTableKeys(self.viewControllerFindCountData);
    UIViewController *mostShowViewController = nil;
    NSInteger mostShowCount = 1;
    for (UIViewController *controller in allViewControllers) {
        NSNumber *countNumber = [self.viewControllerFindCountData objectForKey:controller];
        if (countNumber.integerValue >= mostShowCount) {
            mostShowCount = countNumber.integerValue;
            mostShowViewController = controller;
        }
    }
    return mostShowViewController;
}

- (void)registWebAlertInfos:(NSArray <NSDictionary *> *)infos {
    if (infos.count > 0) {
        // 通过 Dictionary 构造所有不同 message 的弹框集合
        NSMutableDictionary *alertMessageInfoDic = [NSMutableDictionary dictionary];
        for (NSDictionary *alertInfo in self.alertInfos) {
            NSString *message = alertInfo[@"message"];
            if (message) {
                alertMessageInfoDic[message] = alertInfo;
            }
        }

        // 只添加 message 不重复的弹框信息
        for (NSDictionary *alertInfo in infos) {
            NSString *message = alertInfo[@"message"];
            if (message && ![alertMessageInfoDic.allKeys containsObject:message]) {
                [self.alertInfos addObject:alertInfo];
            }
        }

        // 强制刷新数据
        SAJSONUtil *jsonUtil = [[SAJSONUtil alloc] init];
        NSData *jsonData = [jsonUtil JSONSerializeObject:infos];
        if (jsonData) {
            NSUInteger hashCode = [jsonData hash];
            [self refreshImageHashMessage:[NSString stringWithFormat:@"%lu", (unsigned long)hashCode]];
        }
    }
}
@end
