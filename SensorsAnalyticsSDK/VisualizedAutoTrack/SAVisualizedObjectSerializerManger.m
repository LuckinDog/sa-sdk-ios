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


@interface SAVisualizedObjectSerializerManger()

/// 是否包含 webview
@property (nonatomic, assign, readwrite) BOOL isContainWebView;

/// 保存不同 controller 元素个数
@property (nonatomic, copy) NSMapTable <UIViewController *, NSNumber *> *viewControllerFindCountData;
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
    [self resetObjectSerializer];
}

/// 重置解析配置
- (void)resetObjectSerializer {
    _isContainWebView = NO;
    [_viewControllerFindCountData removeAllObjects];
}

- (void)enterWebViewPage {
    self.isContainWebView = YES;
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
@end
