//
// SAVisualizedUtils.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/3/3.
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

#import "SAVisualizedUtils.h"
#import "SAJSTouchEventView.h"
#import "SAVisualizedViewPathProperty.h"
#import "SAJSONUtil.h"
#import "SAVisualizedObjectSerializerManger.h"


@implementation SAVisualizedUtils


+ (BOOL)isCoveredForView:(UIView *)view {
    BOOL covered = NO;
    
    // 最多查找 3 层
    NSArray <UIView *> *allOtherViews = [self findAllPossibleCoverViews:view hierarchyCount:3];

    // 遍历判断是否存在覆盖
    CGRect rect = [view convertRect:view.bounds toView:nil];
    for (UIView *otherView in allOtherViews) {
        CGRect otherRect = [otherView convertRect:otherView.bounds toView:nil];
        if (CGRectContainsRect(otherRect, rect)) {
            return YES;
        }
    }
    return covered;
}


// 根据层数，查询一个 view 所有可能覆盖的 view
+ (NSArray *)findAllPossibleCoverViews:(UIView *)view hierarchyCount:(NSInteger)count {
    __block NSMutableArray <UIView *> *allOtherViews = [NSMutableArray array];
    NSInteger index = count;
    UIView *currentView = view;
    while (index > 0 && currentView) {
        NSArray *allBrotherViews = [self findPossibleCoverAllBrotherViews:currentView];
          if (allBrotherViews.count > 0) {
              [allOtherViews addObjectsFromArray:allBrotherViews];
          }
        currentView = currentView.superview;
        index--;
    }
    return [allOtherViews copy];
}


// 寻找一个 view 同级的后添加的 view
+ (NSArray *)findPossibleCoverAllBrotherViews:(UIView *)view {
    __block NSMutableArray <UIView *> *otherViews = [NSMutableArray array];
    UIView *superView = view.superview;
    if (superView) {
        // 逆序遍历
        [superView.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIView *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if (obj == view) {
                *stop = YES;
            } else if (obj.alpha > 0 && !obj.hidden && obj.userInteractionEnabled) { // userInteractionEnabled 为 YES 才有可能遮挡响应事件
                [otherViews addObject:obj];
            }
        }];
    }
    return otherViews;
}

+ (NSArray *)analysisWebElementWithWebView:(WKWebView <SAVisualizedExtensionProperty> *)webView {
    SAVisualizedWebPageInfo *webPageInfo = [[SAVisualizedObjectSerializerManger sharedInstance] readWebPageInfoWithWebView:webView];
    NSArray *webPageDatas = webPageInfo.elementSources;
    if (webPageDatas.count == 0) {
        return nil;
    }

    // 元素去重，去除 id 相同的重复元素
    NSMutableArray <NSString *> *allNoRepeatElementIds = [NSMutableArray array];

    UIScrollView *scrollView = webView.scrollView;
    /// webView 缩放系数
    CGFloat zoomScale = scrollView.zoomScale;
    // 位置偏移量
    CGPoint contentOffset = scrollView.contentOffset;
    NSMutableArray *touchViewArray = [NSMutableArray array];
    for (NSDictionary *pageData in webPageDatas) {
        NSString *elementId = pageData[@"id"];
        if (elementId) {
            if ([allNoRepeatElementIds containsObject:elementId]) {
                continue;
            }
            [allNoRepeatElementIds addObject:elementId];
        }

        // NSInteger scale = [pageData[@"scale"] integerValue];
        CGFloat left = [pageData[@"left"] floatValue] * zoomScale;
        CGFloat top = [pageData[@"top"] floatValue] * zoomScale;
        CGFloat width = [pageData[@"width"] floatValue] * zoomScale;
        CGFloat height = [pageData[@"height"] floatValue] * zoomScale;
        CGFloat scrollX = [pageData[@"scrollX"] floatValue] * zoomScale;
        CGFloat scrollY = [pageData[@"scrollY"] floatValue] * zoomScale;
        BOOL visibility = [pageData[@"visibility"] boolValue];
        NSArray <NSString *> *subelements = pageData[@"subelements"];

        if (height > 0 && visibility) {
            CGPoint subviwePoint = [webView convertPoint:CGPointMake(0, 0) toView:nil];
            CGFloat realX = left + subviwePoint.x - contentOffset.x + scrollX;
            CGFloat realY = top + subviwePoint.y - contentOffset.y + scrollY;

            SAJSTouchEventView *touchView = [[SAJSTouchEventView alloc] initWithFrame:CGRectMake(realX, realY, width, height)];
            touchView.userInteractionEnabled = YES;
            touchView.elementContent = pageData[@"$element_content"];
            touchView.elementSelector = pageData[@"$element_selector"];
            touchView.visibility = visibility;
            touchView.url = pageData[@"$url"];
            touchView.tagName = pageData[@"tagName"];
            touchView.title = pageData[@"$title"];
            touchView.isFromH5 = YES;
            touchView.jsElementId = elementId;
            touchView.jsSubElementIds = subelements;
            [touchViewArray addObject:touchView];
        }
    }

    // 构建子元素数组
    for (SAJSTouchEventView *touchView1 in [touchViewArray copy]) {
        //当前元素嵌套子元素
        if (touchView1.jsSubElementIds.count > 0) {
            NSMutableArray *jsSubElement = [NSMutableArray arrayWithCapacity:touchView1.jsSubElementIds.count];
            // 根据子元素 id 查找对应子元素
            for (NSString *elementId in touchView1.jsSubElementIds) {
                for (SAJSTouchEventView *touchView2 in [touchViewArray copy]) {
                    if ([elementId isEqualToString:touchView2.jsElementId]) {
                        [jsSubElement addObject:touchView2];
                        [touchViewArray removeObject:touchView2];
                    }
                }
            }
            touchView1.jsSubviews = [jsSubElement copy];
        }
    }
    return [touchViewArray copy];
}

@end
