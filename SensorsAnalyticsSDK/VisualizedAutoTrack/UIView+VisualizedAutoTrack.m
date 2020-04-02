//
// UIView+VisualizedAutoTrack.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/3/6.
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

#import "UIView+VisualizedAutoTrack.h"
#import <objc/runtime.h>
#import "UIView+AutoTrack.h"
#import "UIViewController+AutoTrack.h"
#import "UIGestureRecognizer+AutoTrack.h"
#import "SAVisualizedUtils.h"
#import "SAAutoTrackUtils.h"

@implementation UIView (VisualizedAutoTrack)

// 判断一个 view 是否显示
- (BOOL)sensorsdata_isDisplayedInScreen {
    if (!(self.window && self.superview && self.alpha > 0) || self.hidden) {
        return NO;
    }
    // 计算 view 在 keyWindow 上的坐标
    CGRect rect = [self convertRect:self.frame toView:nil];
    // 若 size 为 CGrectZero
    // 部分 view 设置宽高为 0，但是子视图可见，取消 CGRectIsEmpty(rect) 判断
    if (CGRectIsNull(rect) || CGSizeEqualToSize(rect.size, CGSizeZero)) {
        return NO;
    }

     // 忽略部分 view
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    // _UIAlertControllerTextFieldViewCollectionCell UIAlertController 中输入框，忽略采集
    //    对应 controller.view 子控件包含了，都忽略，避免重复
    if ([NSStringFromClass(self.class) isEqualToString:@"_UIAlertControllerTextFieldViewCollectionCell"]) {
        return NO;
    }

    if ([NSStringFromClass(self.class) isEqualToString:@"UITransitionView"] && self.superview == [UIApplication sharedApplication].keyWindow) {
        return NO;
    }
#endif

    return YES;
}

// 判断一个 view 是否会触发全埋点事件
- (BOOL)sensorsdata_isAutoTrackAppClick {
    // 判断是否被覆盖
    if ([SAVisualizedUtils isCoveredForView:self]) {
        return NO;
    }

    if ([SAAutoTrackUtils isAlertForResponder:self]) { // 位于弹框
        if ([SAAutoTrackUtils isAlertClickForView:self]) { // 弹框选项
            return YES;
        }
        return NO;
    }

    // 处理特殊控件
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    // UISegmentedControl 嵌套 UISegment 作为选项单元格，特殊处理
    if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"]) {
        return YES;
    }
#endif

    if ([self isKindOfClass:UIControl.class]) {
        // UISegmentedControl 高亮渲染内部嵌套的 UISegment
        if ([self isKindOfClass:UISegmentedControl.class]) {
            return NO;
        }

        // 部分控件，响应链中不采集 $AppClick 事件
        if ([self isKindOfClass:UITextField.class]) {
            return NO;
        }

        UIControl *control = (UIControl *)self;
        BOOL userInteractionEnabled = control.userInteractionEnabled;
        BOOL enabled = control.enabled;
        UIControlEvents appClickEvents = UIControlEventTouchUpInside | UIControlEventValueChanged;
        if (@available(iOS 9.0, *)) {
            appClickEvents = appClickEvents | UIControlEventPrimaryActionTriggered;
        }
        BOOL containEvents = appClickEvents & control.allControlEvents;
        if (containEvents && userInteractionEnabled && enabled) {     // 可点击
            return YES;
        }
    } else if ([self isKindOfClass:UITableViewCell.class]) {
        UITableView *tableView = (UITableView *)[self superview];
        do {
            if ([tableView isKindOfClass:UITableView.class]) {
                if (tableView.delegate && [tableView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
                    return YES;
                }
            }
        } while ((tableView = (UITableView *)[tableView superview]));

        return NO;
    } else if ([self isKindOfClass:UICollectionViewCell.class]) {
        UICollectionView *collectionView = (UICollectionView *)[self superview];
        if ([collectionView isKindOfClass:UICollectionView.class]) {
            if (collectionView.delegate && [collectionView.delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
                return YES;
            }
        }
        return NO;
    } else if (self.userInteractionEnabled && self.gestureRecognizers.count > 0) {// UIView 可能添加手势
        __block BOOL enableGestureClick = NO;
        [self.gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            // 目前 $AppClick 只采集 UITapGestureRecognizer 和 UILongPressGestureRecognizer
            if (([obj isKindOfClass:UITapGestureRecognizer.class] || [obj isKindOfClass:UILongPressGestureRecognizer.class]) && !obj.sensorsdata_isPrivateAction) {
                *stop = YES;
                enableGestureClick = YES;
            }
        }];
        return enableGestureClick;
    }
    return NO;
}
#pragma mark SAVisualizedViewPathProperty
// 当前元素，前端是否渲染成可交互
- (BOOL)sensorsdata_enableAppClick {
    //是否在屏幕显示
    BOOL isDisplayedInScreen = self.sensorsdata_isDisplayedInScreen;
    // 是否触发 $AppClick 事件
    BOOL isAutoTrackAppClick = self.sensorsdata_isAutoTrackAppClick;
    BOOL enableAppClick = isDisplayedInScreen && isAutoTrackAppClick;
    return enableAppClick;
}

- (NSString *)sensorsdata_elementValidContent {
    return self.sensorsdata_elementContent;
}

/// 元素子视图
- (NSArray *)sensorsdata_subElements {
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    // controller1.vew 上直接添加 controller2.view, 在 controller2 添加 UITabBarController.view 或 UINavigationController.view  场景兼容
    if ([NSStringFromClass(self.class) isEqualToString:@"UILayoutContainerView"]) {
        if ([[self nextResponder] isKindOfClass:UIViewController.class]) {
            UIViewController *controller = (UIViewController *)[self nextResponder];
            return controller.sensorsdata_subElements;
        }
    }
#endif
    NSMutableArray *newSubViews = [NSMutableArray array];
    for (UIView *view in self.subviews) {
        if (view.sensorsdata_isDisplayedInScreen) {
            [newSubViews addObject:view];
        }
    }
    return newSubViews;
}

- (void)setSensorsdata_elementPath:(NSString *)sensorsdata_elementPath {
    objc_setAssociatedObject(self, @"sensorsAnalyticsElementPath", sensorsdata_elementPath, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)sensorsdata_elementPath {
    NSString *elementPath = objc_getAssociatedObject(self, @"sensorsAnalyticsElementPath");
    if (elementPath) {
        return elementPath;
    }

    // 忽略 viewPath 路径
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    if ([NSStringFromClass(self.class) isEqualToString:@"UILayoutContainerView"] || [NSStringFromClass(self.class) isEqualToString:@"UITransitionView"]) {
        return nil;
    }

    /*
     如果 UITabBarController.view 或 UINavigationController.view 添加到了 controller.vew 上，并且未执行 addChildViewController
        1. 忽略当前 controller.vew 的相对路径；
        2. controller.vew 的其他子视图相对路径，再拼接当前元素路径
     */
    BOOL isContainContainerView = NO;
    for (UIView *view in self.subviews) {
        if ([NSStringFromClass(view.class) isEqualToString:@"UILayoutContainerView"]) {
            isContainContainerView = YES;
        }
    }

    if (isContainContainerView) {
        for (UIView *view in self.subviews) {
            if (![NSStringFromClass(view.class) isEqualToString:@"UILayoutContainerView"]) {
                [view setSensorsdata_elementPath:[NSString stringWithFormat:@"%@/%@", self.sensorsdata_itemPath, view.sensorsdata_itemPath]];
            }
        }
        return nil;
    }
#endif

    // keyWindow 上添加元素路径拼接
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (self.superview == keyWindow && self != keyWindow.rootViewController.view) { // 兼容 keyWindow 上控件的路径拼接
        if (self.sensorsdata_similarPath) {
            return [NSString stringWithFormat:@"%@/%@", keyWindow.sensorsdata_elementPath, self.sensorsdata_similarPath];
        }
    }
    return self.sensorsdata_similarPath;
}

- (CGRect)sensorsdata_frame {
    CGRect showRect = [self convertRect:self.bounds toView:nil];
    if (self.superview && self.sensorsdata_enableAppClick) {
        CGRect validFrame = self.superview.sensorsdata_validFrame;
        showRect = CGRectIntersection(showRect, validFrame);
    }
    return showRect;
}

- (CGRect)sensorsdata_validFrame {
    CGRect validFrame = [UIApplication sharedApplication].keyWindow.frame;
    if (self.superview) {
        CGRect superViewValidFrame = [self.superview sensorsdata_validFrame];
        validFrame = CGRectIntersection(validFrame, superViewValidFrame);
    }
 return validFrame;
}

@end


@implementation UIScrollView (VisualizedAutoTrack)

- (CGRect)sensorsdata_validFrame {
    CGRect showRect = [self convertRect:self.bounds toView:nil];
    if (self.superview) {
        CGRect superViewValidFrame = [self.superview sensorsdata_validFrame];
        showRect = CGRectIntersection(showRect, superViewValidFrame);
    }
    return showRect;
}

@end

@implementation UISwitch (VisualizedAutoTrack)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end

@implementation UIStepper (VisualizedAutoTrack)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end

@implementation UISlider (VisualizedAutoTrack)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end

@implementation UIPageControl (VisualizedAutoTrack)

- (NSString *)sensorsdata_elementValidContent {
    return nil;
}

@end

@implementation UISegmentedControl (VisualizedAutoTrack)

- (NSString *)sensorsdata_elementPath {
    return super.sensorsdata_itemPath;
}

@end

@implementation UIWindow (VisualizedAutoTrack)

- (NSArray *)sensorsdata_subElements {
    if ([UIApplication sharedApplication].keyWindow != self) {
        return super.sensorsdata_subElements;
    }

    NSMutableArray *subElements = [NSMutableArray array];
    [subElements addObject:self.rootViewController];

    // 存在自定义弹框或浮层，位于 keyWindow
    NSArray <UIView *> *subviews = self.subviews;
    for (UIView *view in subviews) {
        if (view != self.rootViewController.view && view.sensorsdata_isDisplayedInScreen) {
            [subElements addObject:view];
            CGRect rect = [view convertRect:view.bounds toView:nil];
            // 是否全屏
            BOOL isFullScreenShow = CGPointEqualToPoint(rect.origin, CGPointMake(0, 0)) && CGSizeEqualToSize(rect.size, self.bounds.size);
            // keyWindow 上存在全屏显示可交互的 view，此时 rootViewController 内元素不可交互
            if (isFullScreenShow && view.userInteractionEnabled) {
                [subElements removeObject:self.rootViewController];
            }
        }
    }
    return subElements;
}

@end

@implementation UITabBar (VisualizedAutoTrack)

- (NSString *)sensorsdata_elementPath {
    return [NSString stringWithFormat:@"UILayoutContainerView/%@",super.sensorsdata_elementPath];
}

@end


@implementation UINavigationBar (VisualizedAutoTrack)
- (NSString *)sensorsdata_elementPath {
    return [NSString stringWithFormat:@"UILayoutContainerView/%@",super.sensorsdata_elementPath];
}
@end

@implementation UITableView (VisualizedAutoTrack)

- (NSArray *)sensorsdata_subElements {
    NSArray *subviews = self.subviews;
    NSMutableArray *newSubviews = [NSMutableArray array];
    NSArray *visibleCells = self.visibleCells;
    for (UIView *view in subviews) {
        if ([view isKindOfClass:UITableViewCell.class]) {
            if ([visibleCells containsObject:view] && view.sensorsdata_isDisplayedInScreen) {
                [newSubviews addObject:view];
            }
        } else if (view.sensorsdata_isDisplayedInScreen) {
            [newSubviews addObject:view];
        }
    }
    return newSubviews;
}

@end

@implementation UICollectionView (VisualizedAutoTrack)

- (NSArray *)sensorsdata_subElements {
    NSArray *subviews = self.subviews;
    NSMutableArray *newSubviews = [NSMutableArray array];
    NSArray *visibleCells = self.visibleCells;
    for (UIView *view in subviews) {
        if ([view isKindOfClass:UICollectionViewCell.class]) {
            if ([visibleCells containsObject:view] && view.sensorsdata_isDisplayedInScreen ) {
                [newSubviews addObject:view];
            }
        } else if (view.sensorsdata_isDisplayedInScreen) {
            [newSubviews addObject:view];
        }
    }
    return newSubviews;
}

@end

@implementation UITableViewCell (VisualizedAutoTrack)

- (NSString *)sensorsdata_elementPosition {
    if (self.sensorsdata_IndexPath) {
        return [[NSString alloc] initWithFormat:@"%ld:%ld", (long)self.sensorsdata_IndexPath.section, (long)self.sensorsdata_IndexPath.row];
    }
    return nil;
}

@end


@implementation UICollectionViewCell (VisualizedAutoTrack)

- (NSString *)sensorsdata_elementPosition {
    if ([SAAutoTrackUtils isAlertClickForView:self]) {
        return nil;
    }

    if (self.sensorsdata_IndexPath) {
        return [[NSString alloc] initWithFormat:@"%ld:%ld", (long)self.sensorsdata_IndexPath.section, (long)self.sensorsdata_IndexPath.item];
    }
    return nil;
}

@end

@implementation UIViewController (VisualizedAutoTrack)

- (NSArray *)sensorsdata_subElements {
    __block NSMutableArray *subElements = [NSMutableArray array];
    NSArray <UIViewController *> *childViewControllers = self.childViewControllers;
    UIViewController *presentedViewController = self.presentedViewController;

    if (presentedViewController) {
        [subElements addObject:presentedViewController];
        return subElements;
    }

    if ([self isKindOfClass:UINavigationController.class]) {
        UINavigationController *nav = (UINavigationController *)self;
        [subElements addObject:nav.topViewController];
        if (self.isViewLoaded && nav.navigationBar.sensorsdata_isDisplayedInScreen) {
            [subElements addObject:nav.navigationBar];
        }
        return subElements;
    }

    if ([self isKindOfClass:UITabBarController.class]) {
        UITabBarController *tabBarVC = (UITabBarController *)self;
        [subElements addObject:tabBarVC.selectedViewController];
        // UITabBar 元素
        if (self.isViewLoaded && tabBarVC.tabBar.sensorsdata_isDisplayedInScreen) {
            [subElements addObject:tabBarVC.tabBar];
        }
        return subElements;
    }

    if (childViewControllers.count > 0 && ![self isKindOfClass:UIAlertController.class]) {
        // UIAlertController 如果添加 TextField 也会嵌套 childViewController，直接返回 .view 即可

        subElements = [NSMutableArray arrayWithArray:self.view.subviews];
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;

        __block BOOL isContainFullScreen = NO; // 是否包含全屏
        //逆序遍历
        [childViewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIViewController *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            UIView *objSuperview = obj.view;
            do {
                if ([subElements containsObject:objSuperview]) {
                    NSInteger index = [subElements indexOfObject:objSuperview];
                    if (objSuperview.sensorsdata_isDisplayedInScreen && !isContainFullScreen) {
                        [subElements replaceObjectAtIndex:index withObject:obj];
                    } else {
                        [subElements removeObject:objSuperview];
                    }
                    break;
                }
                //childViewController.view 可能不直接添加在 self.view，而是在子视图
            } while ((objSuperview = objSuperview.superview));

            CGRect rect = [obj.view convertRect:obj.view.bounds toView:nil];
            // 是否全屏
            BOOL isFullScreenShow = CGPointEqualToPoint(rect.origin, CGPointMake(0, 0)) && CGSizeEqualToSize(rect.size, keyWindow.bounds.size);
            // 正在全屏显示
            if (isFullScreenShow && obj.view.sensorsdata_isDisplayedInScreen) {
                isContainFullScreen = YES;
            }
        }];
        return subElements;
    }

    if ([self isKindOfClass:UIPageViewController.class]) {
        UIPageViewController *pageViewController = (UIPageViewController *)self;
        [subElements addObject:pageViewController.viewControllers];
    }

    UIView *currentView = self.view;
    if (currentView && self.isViewLoaded && currentView.sensorsdata_isDisplayedInScreen) {
        [subElements addObject:currentView];
    }
    return subElements;
}

- (NSString *)sensorsdata_elementPath {
    
    if ([self isKindOfClass:UIAlertController.class]) {
        return self.sensorsdata_itemPath;
    }

    // 前端 viewPath 拼接，屏蔽页面信息
    return nil;
}

@end
