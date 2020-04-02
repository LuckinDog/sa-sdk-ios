//
//  UIGestureRecognizer+AutoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2018/10/25.
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


#import "UIGestureRecognizer+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "UIView+AutoTrack.h"
#import "SAAutoTrackUtils.h"
#import "SALogger.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import <objc/runtime.h>
#import "SAConstants.h"

@implementation UIGestureRecognizer (AutoTrack)

- (void)trackGestureRecognizerAppClick:(UIGestureRecognizer *)gesture {
    @try {
        // 手势处于 Ended 状态
        if (gesture.state != UIGestureRecognizerStateEnded) {
            return;
        }
        
        UIView *view = gesture.view;
        // iOS10 及以上 _UIAlertControllerInterfaceActionGroupView
        // iOS 9 及以下 _UIAlertControllerView
        // 点击在弹框上
        if ([SAAutoTrackUtils isAlertForResponder:view]) {
            UIView *touchView = [self searchGestureTouchView:gesture];
            if (touchView) {
                view = touchView;
            }
        }

        // 是否弹框选项点击
        BOOL isAlertClick = [SAAutoTrackUtils isAlertClickForView:view];
        // 采集开发者添加的 UIView 手势，屏蔽系统添加的私有手势
        BOOL isTrackClass = ([view isKindOfClass:UIView.class] && !gesture.sensorsdata_isPrivateAction) || isAlertClick;
        BOOL isIgnored = ![view conformsToProtocol:@protocol(SAAutoTrackViewProperty)] || view.sensorsdata_isIgnored;
        if (!isTrackClass || isIgnored) {
            return;
        }
        NSDictionary *properties = [SAAutoTrackUtils propertiesWithAutoTrackObject:view];
        if (properties) {
            [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
        }
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

// 查找弹框手势选择所在的 view
- (UIView *)searchGestureTouchView:(UIGestureRecognizer *)gesture {
    UIView *gestureView = gesture.view;
    CGPoint point = [gesture locationInView:gestureView];

    UIView *view = [gestureView.subviews lastObject];
    UIView *sequeceView = [view.subviews lastObject];
    UIView *reparatableVequeceView = [sequeceView.subviews firstObject];
    UIView *stackView = [reparatableVequeceView.subviews firstObject];

#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    if ([NSStringFromClass(gestureView.class) isEqualToString:@"_UIAlertControllerView"]) {
        // iOS9 上，为 UICollectionView
        stackView = [reparatableVequeceView.subviews lastObject];
    }
#endif
    
    for (UIView *subView in stackView.subviews) {
        CGRect rect = [subView convertRect:subView.bounds toView:gestureView];
        if (CGRectContainsPoint(rect, point)) { // 找到 _UIAlertControllerActionView，及 UIAlertController 响应点击的 view
            // subView 类型为 _UIInterfaceActionCustomViewRepresentationView
            // iOS9 上为 _UIAlertControllerCollectionViewCell
            return subView;
        }
    }
    return nil;
}


- (BOOL)sensorsdata_isPrivateAction {
    return [objc_getAssociatedObject(self, @"sensorsdataPrivateGestureRecognizerAction") boolValue];
}


- (void)setSensorsdata_isPrivateAction:(BOOL)sensorsdata_isPrivateAction {
    objc_setAssociatedObject(self, @"sensorsdataPrivateGestureRecognizerAction", [NSNumber numberWithBool:sensorsdata_isPrivateAction], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)sensorsdata_isPrivateGestureWithTarget:(id)target action:(SEL)action {
    if (action) {
        NSString *actionName = NSStringFromSelector(action);
        // 下划线前缀的手势 action 名称，一般为系统添加
        if ([actionName hasPrefix:@"_"]) {
            return YES;
        }
    }
    // target 为系统类型，一般为私有手势
    if (target) {
        NSString *bundlePath = [[NSBundle bundleForClass:[target class]] bundlePath];
        /* 系统库
         /System/Library/PrivateFrameworks/UIKitCore.framework
         /System/Library/Frameworks/WebKit.framework

         开发者创建
         /private/var/containers/Bundle/Application/8264D420-DE23-48AC-9985-A7F1E131A52A/CDDStoreDemo.app
         */
        //根据 bundleURL 的 path 判断是否为系统库
        NSMutableArray<NSString *> *pathComponents = [bundlePath.pathComponents mutableCopy];
        [pathComponents removeObject:@"/"];
        if (pathComponents.count > 1) {
            NSString *systemPath = [[pathComponents subarrayWithRange:NSMakeRange(0, 2)] componentsJoinedByString:@"/"];
            if ([systemPath isEqualToString:@"System/Library"]) {
                return YES;
            }
        }
    }
    return NO;
}
@end


@implementation UITapGestureRecognizer (AutoTrack)

- (instancetype)sa_initWithTarget:(id)target action:(SEL)action {
    [self sa_initWithTarget:target action:action];
    [self removeTarget:target action:action];
    [self addTarget:target action:action];
    return self;
}

- (void)sa_addTarget:(id)target action:(SEL)action {
    if ([self sensorsdata_isPrivateGestureWithTarget:target action:action]) {
        self.sensorsdata_isPrivateAction = YES;
    }
    [self sa_addTarget:self action:@selector(trackGestureRecognizerAppClick:)];
    [self sa_addTarget:target action:action];
}

@end



@implementation UILongPressGestureRecognizer (AutoTrack)

- (instancetype)sa_initWithTarget:(id)target action:(SEL)action {
    [self sa_initWithTarget:target action:action];
    [self removeTarget:target action:action];
    [self addTarget:target action:action];
    return self;
}

- (void)sa_addTarget:(id)target action:(SEL)action {
    if ([self sensorsdata_isPrivateGestureWithTarget:target action:action]) {
        self.sensorsdata_isPrivateAction = YES;
    }
    [self sa_addTarget:self action:@selector(trackGestureRecognizerAppClick:)];
    [self sa_addTarget:target action:action];
}
@end
