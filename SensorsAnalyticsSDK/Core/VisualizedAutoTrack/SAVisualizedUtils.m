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
#import "SALog.h"

/// 判断 RNView 覆盖后对交互的影响类型
typedef NS_ENUM(NSInteger, SensorsAnalyticsRNViewCoveredType) {
    /// 不做特殊处理，正常覆盖逻辑判断
    SensorsAnalyticsRNViewCoveredTypeDefault,
    /// 不会遮挡下面元素点击，可以跳过
    SensorsAnalyticsRNViewCoveredTypeNone,
    /// 阻挡底下元素点击
    SensorsAnalyticsRNViewCoveredTypeStop,
};

/// 遍历查找页面最大层数，用于判断元素是否被覆盖
static NSInteger kSAVisualizedFindMaxPageLevel = 7;

@implementation SAVisualizedUtils


+ (BOOL)isCoveredForView:(UIView *)view {
    NSArray <UIView *> *allOtherViews = [self findAllPossibleCoverViews:view hierarchyCount:kSAVisualizedFindMaxPageLevel];

    // 遍历判断是否存在覆盖
    CGRect originalRect = [view convertRect:view.bounds toView:nil];
    // 视图可能超出屏幕，计算 keywindow 交集，即在屏幕显示的有效区域
    CGRect keyWindowFrame = [UIApplication sharedApplication].keyWindow.frame;
    CGRect rect = CGRectIntersection(keyWindowFrame, originalRect);

    for (UIView *otherView in allOtherViews) {
        Class RNViewClass = NSClassFromString(@"RCTView");
        BOOL isRNView =  RNViewClass && [otherView isKindOfClass:RNViewClass];
        if (isRNView) {
            SensorsAnalyticsRNViewCoveredType coveredType = [self coveredTypeOfRNView:view fromRNView:otherView];
            // 被覆盖，阻塞底部元素点击，
            if (coveredType == SensorsAnalyticsRNViewCoveredTypeStop) {
                return YES;
            // 不会遮挡下面元素点击，可以跳过该 view
            } else if (coveredType == SensorsAnalyticsRNViewCoveredTypeNone) {
                continue;
            }
        }

        CGRect otherRect = [otherView convertRect:otherView.bounds toView:nil];
        if (CGRectContainsRect(otherRect, rect)) {
            return YES;
        }
    }
    return NO;
}

/// 判断 RNView 被遮挡元素覆盖的类型
/// @param view 被遮挡的 RNView
/// @param fromView 遮挡的 RNView
+ (SensorsAnalyticsRNViewCoveredType)coveredTypeOfRNView:(UIView *)view fromRNView:(UIView *)fromView {
    // 遍历判断是否存在覆盖
    CGRect rect = [view convertRect:view.bounds toView:nil];
    // 视图可能超出屏幕，计算 keywindow 交集，即在屏幕显示的有效区域
    CGRect keyWindowFrame = [UIApplication sharedApplication].keyWindow.frame;
    rect = CGRectIntersection(keyWindowFrame, rect);

    @try {
        /* RCTView 默认重写了 hitTest:
         详情参照：https://github.com/facebook/react-native/blob/master/React/Views/RCTView.m
         针对 RN 部分框架或实现方式，设置 pointerEvents 并在 hitTest: 内判断处理，从而实现交互的穿透，不响应当前 RNView
         */
        NSInteger pointerEvents = [[fromView valueForKey:@"pointerEvents"] integerValue];
        if (pointerEvents == 1) {
            return SensorsAnalyticsRNViewCoveredTypeNone;
        }
        if (pointerEvents == 2) {
            // 寻找完全遮挡 view 的子视图
            for (UIView *subView in fromView.subviews) {
                if (subView.alpha <= 0.01 || subView.hidden || !subView.userInteractionEnabled) {
                    continue;
                }
                CGRect subViewRect = [subView convertRect:subView.bounds toView:nil];
                if (CGRectContainsRect(subViewRect, rect)) {
                    return SensorsAnalyticsRNViewCoveredTypeStop;
                }
            }
            return SensorsAnalyticsRNViewCoveredTypeNone;
        }
    } @catch (NSException *exception) {
        SALogDebug(@"%@ error: %@", self, exception);
    }
    return SensorsAnalyticsRNViewCoveredTypeDefault;
}

// 根据层数，查询一个 view 所有可能覆盖的 view
+ (NSArray *)findAllPossibleCoverViews:(UIView *)view hierarchyCount:(NSInteger)count {
    NSMutableArray <UIView *> *allOtherViews = [NSMutableArray array];
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
    UIResponder *nextResponder = [view nextResponder];
    if ([nextResponder isKindOfClass:UIView.class]) {
        UIView *superView = (UIView *)nextResponder;
        // 逆序遍历
        [superView.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIView *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if (obj == view) {
                *stop = YES;
            } else if (obj.alpha > 0.01 && !obj.hidden && obj.userInteractionEnabled) { // userInteractionEnabled 为 YES 才有可能遮挡响应事件
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
    NSMutableArray <SAJSTouchEventView *> *touchViewArray = [NSMutableArray array];
    for (NSDictionary *pageData in webPageDatas) {
        NSString *elementId = pageData[@"id"];
        if (elementId) {
            if ([allNoRepeatElementIds containsObject:elementId]) {
                continue;
            }
            [allNoRepeatElementIds addObject:elementId];
        }

        SAJSTouchEventView *touchView = [[SAJSTouchEventView alloc] initWithWebView:webView webElementInfo:pageData];
        if (touchView) {
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

+ (NSDictionary *)currentRNScreenVisualizeProperties {
    // 获取 RN 页面信息
    NSDictionary <NSString *, NSString *> *RNScreenInfo = nil;
    Class managerClass = NSClassFromString(@"SAReactNativeManager");
    SEL sharedInstanceSEL = NSSelectorFromString(@"sharedInstance");
    if ([managerClass respondsToSelector:sharedInstanceSEL]) {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id manager = [managerClass performSelector:sharedInstanceSEL];
        SEL propsSEL = NSSelectorFromString(@"visualizeProperties");
        if ([manager respondsToSelector:propsSEL]) {
            RNScreenInfo = [manager performSelector:propsSEL];
        }
    #pragma clang diagnostic pop
    }
    return RNScreenInfo;
}
@end
