//
//  UIViewController+AutoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/10/18.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "UIViewController+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "SAConstants+Private.h"
#import "SACommonUtility.h"
#import "SALog.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "UIView+AutoTrack.h"
#import "SAAutoTrackManager.h"
#import "SAWeakPropertyContainer.h"
#import <objc/runtime.h>

static void *const kSAPreviousViewController = (void *)&kSAPreviousViewController;

@implementation UIViewController (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    return ![[SAAutoTrackManager sharedInstance].appClickTracker shouldTrackViewController:self];
}

- (NSString *)sensorsdata_screenName {
    return NSStringFromClass([self class]);
}

- (NSString *)sensorsdata_title {
    __block NSString *titleViewContent = nil;
    __block NSString *controllerTitle = nil;
    [SACommonUtility performBlockOnMainThread:^{
        titleViewContent = self.navigationItem.titleView.sensorsdata_elementContent;
        controllerTitle = self.navigationItem.title;
    }];
    if (titleViewContent.length > 0) {
        return titleViewContent;
    }

    if (controllerTitle.length > 0) {
        return controllerTitle;
    }
    return nil;
}

- (void)sa_autotrack_viewDidAppear:(BOOL)animated {
    @try {

        // 防止 tabbar 切换，可能漏采 $AppViewScreen 全埋点
        if ([self isKindOfClass:UINavigationController.class]) {
            self.sensorsdata_previousViewController = nil;
        }

        SAAppViewScreenTracker *appViewScreenTracker = SAAutoTrackManager.sharedInstance.appViewScreenTracker;

        if (!appViewScreenTracker.ignored) {
#ifndef SENSORS_ANALYTICS_ENABLE_AUTOTRACK_CHILD_VIEWSCREEN
            UIViewController *viewController = (UIViewController *)self;
            if (!viewController.parentViewController ||
                [viewController.parentViewController isKindOfClass:[UITabBarController class]] ||
                [viewController.parentViewController isKindOfClass:[UINavigationController class]] ||
                [viewController.parentViewController isKindOfClass:[UIPageViewController class]] ||
                [viewController.parentViewController isKindOfClass:[UISplitViewController class]]) {
                [appViewScreenTracker autoTrackEventWithViewController:viewController];
            }
#else
            [appViewScreenTracker autoTrackEventWithViewController:self];
#endif
        }
    } @catch (NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
    [self sa_autotrack_viewDidAppear:animated];
}

- (void)setSensorsdata_previousViewController:(UIViewController *)sensorsdata_previousViewController {
    SAWeakPropertyContainer *container = [SAWeakPropertyContainer containerWithWeakProperty:sensorsdata_previousViewController];
    objc_setAssociatedObject(self, kSAPreviousViewController, container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController *)sensorsdata_previousViewController {
    SAWeakPropertyContainer *container = objc_getAssociatedObject(self, kSAPreviousViewController);
    return container.weakProperty;
}

@end
