//
// SAReactNativeManager.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/8/13.
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

#import "SAReactNativeManager.h"
#import "SensorsAnalyticsSDK.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAAutoTrackUtils.h"
#import "SAConstants+Private.h"
#import "SALog.h"
#import <UIKit/UIKit.h>
#include <objc/runtime.h>

@implementation SAReactNativeManager

- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (enable) {
        sa_methodExchange("RCTUIManager", "setJSResponder:blockNativeResponder:", "sda_setJSResponder:blockNativeResponder:", (IMP)sa_imp_setJSResponderBlockNativeResponder);
    }
}

static inline void sa_methodExchange(const char *className, const char *originalMethodName, const char *replacementMethodName, IMP imp) {
    @try {
        Class cls = objc_getClass(className);//得到指定类的类定义
        SEL oriSEL = sel_getUid(originalMethodName);//把originalMethodName注册到RunTime系统中
        Method oriMethod = class_getInstanceMethod(cls, oriSEL);//获取实例方法
        struct objc_method_description *desc = method_getDescription(oriMethod);//获得指定方法的描述
        if (desc->types) {
            SEL buSel = sel_registerName(replacementMethodName);//把replacementMethodName注册到RunTime系统中
            if (class_addMethod(cls, buSel, imp, desc->types)) {//通过运行时，把方法动态添加到类中
                Method buMethod  = class_getInstanceMethod(cls, buSel);//获取实例方法
                method_exchangeImplementations(oriMethod, buMethod);//交换方法
            }
        }
    } @catch (NSException *exception) {
        SALogError(@"%@ error: %@", [SensorsAnalyticsSDK sharedInstance], exception);
    }
}

static void sa_imp_setJSResponderBlockNativeResponder(id obj, SEL cmd, id reactTag, BOOL blockNativeResponder) {
    //先执行原来的方法
    SEL oriSel = sel_getUid("sda_setJSResponder:blockNativeResponder:");
    void (*setJSResponderWithBlockNativeResponder)(id, SEL, id, BOOL) = (void (*)(id, SEL, id, BOOL))[NSClassFromString(@"RCTUIManager") instanceMethodForSelector:oriSel];//函数指针
    setJSResponderWithBlockNativeResponder(obj, cmd, reactTag, blockNativeResponder);

    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            //关闭 AutoTrack
            if (![[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled]) {
                return;
            }

            //忽略 $AppClick 事件
            if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
                return;
            }

            if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[NSClassFromString(@"RNView") class]]) {
                return;
            }

            if ([obj isKindOfClass:NSClassFromString(@"RCTUIManager")]) {
                SEL viewForReactTagSelector = NSSelectorFromString(@"viewForReactTag:");
                UIView *uiView = ((UIView* (*)(id, SEL, NSNumber *))[obj methodForSelector:viewForReactTagSelector])(obj, viewForReactTagSelector, reactTag);
                NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];

                if ([uiView isKindOfClass:[NSClassFromString(@"RCTSwitch") class]] || [uiView isKindOfClass:[NSClassFromString(@"RCTScrollView") class]]) {
                    //好像跟 UISwitch 会重复
                    return;
                }

                [properties setValue:@"RNView" forKey:SA_EVENT_PROPERTY_ELEMENT_TYPE];
                [properties setValue:[uiView.accessibilityLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] forKey:SA_EVENT_PROPERTY_ELEMENT_CONTENT];

                UIViewController *viewController = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                if ([uiView respondsToSelector:NSSelectorFromString(@"reactViewController")]) {
                    viewController = [uiView performSelector:NSSelectorFromString(@"reactViewController")];
                }
#pragma clang diagnostic pop
                if (viewController) {
                    //获取 Controller 名称($screen_name)
                    NSString *screenName = NSStringFromClass([viewController class]);
                    [properties setValue:screenName forKey:SA_EVENT_PROPERTY_SCREEN_NAME];

                    NSString *controllerTitle = viewController.navigationItem.title;
                    if (controllerTitle != nil) {
                        [properties setValue:viewController.navigationItem.title forKey:SA_EVENT_PROPERTY_TITLE];
                    }

                    NSString *viewPath = [SAAutoTrackUtils viewSimilarPathForView:uiView atViewController:viewController shouldSimilarPath:NO];
                    if (viewPath) {
                        properties[SA_EVENT_PROPERTY_ELEMENT_PATH] = viewPath;
                    }
                }

                [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
            }
        } @catch (NSException *exception) {
            SALogError(@"%@ error: %@", [SensorsAnalyticsSDK sharedInstance], exception);
        }
    });
}

@end
