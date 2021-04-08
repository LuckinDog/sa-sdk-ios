//
// SAAutoTrackManager.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/4/2.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAAutoTrackManager.h"
#import "SAConfigOptions.h"
#import "SARemoteConfigManager.h"
#import "SensorsAnalyticsSDK+Public.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAModuleManager.h"
#import "SAAppLifecycle.h"
#import "SAConstants+Private.h"
#import "SAConfigOptions.h"
#import "SALog.h"
#import "UIApplication+AutoTrack.h"
#import "UIViewController+AutoTrack.h"
#import "SASwizzle.h"
#import "NSObject+DelegateProxy.h"

@interface SAAutoTrackManager ()

@property (nonatomic, strong) SAAppStartTracker *appStartTracker;
@property (nonatomic, strong) SAAppEndTracker *appEndTracker;

@property (nonatomic, getter=isDisableSDK) BOOL disableSDK;

@end

@implementation SAAutoTrackManager

#pragma mark - SAModuleProtocol

- (instancetype)init {
    self = [super init];
    if (self) {
        _appStartTracker = [[SAAppStartTracker alloc] init];
        _appEndTracker = [[SAAppEndTracker alloc] init];

        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(appLifecycleStateDidChange:) name:kSAAppLifecycleStateDidChangeNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(remoteConfigModelChanged:) name:SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION object:nil];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self name:SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:kSAAppLifecycleStateDidChangeNotification object:nil];
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (enable) {
        [self enableAutoTrack];
    }
}

- (void)enableAutoTrack {
    // 监听所有 UIViewController 显示事件
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //$AppViewScreen
        [UIViewController sa_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(sa_autotrack_viewDidAppear:) error:NULL];
        NSError *error = NULL;
        //$AppClick
        // Actions & Events
        [UIApplication sa_swizzleMethod:@selector(sendAction:to:from:forEvent:)
                             withMethod:@selector(sa_sendAction:to:from:forEvent:)
                                  error:&error];
        if (error) {
            SALogError(@"Failed to swizzle sendAction:to:forEvent: on UIAppplication. Details: %@", error);
            error = NULL;
        }

        SEL selector = NSSelectorFromString(@"sensorsdata_setDelegate:");
        [UITableView sa_swizzleMethod:@selector(setDelegate:) withMethod:selector error:NULL];
        [NSObject sa_swizzleMethod:@selector(respondsToSelector:) withMethod:@selector(sensorsdata_respondsToSelector:) error:NULL];
        [UICollectionView sa_swizzleMethod:@selector(setDelegate:) withMethod:selector error:NULL];
    });

    //React Native
#ifdef SENSORS_ANALYTICS_REACT_NATIVE
    if (NSClassFromString(@"RCTUIManager")) {
        //        [SASwizzler swizzleSelector:NSSelectorFromString(@"setJSResponder:blockNativeResponder:") onClass:NSClassFromString(@"RCTUIManager") withBlock:reactNativeAutoTrackBlock named:@"track_React_Native_AppClick"];
        sa_methodExchange("RCTUIManager", "setJSResponder:blockNativeResponder:", "sda_setJSResponder:blockNativeResponder:", (IMP)sa_imp_setJSResponderBlockNativeResponder);
    }
#endif
}

#pragma mark - Instance

+ (SAAutoTrackManager *)sharedInstance {
    return (SAAutoTrackManager *)[SAModuleManager.sharedInstance managerForModuleType:SAModuleTypeAutoTrack];
}

#pragma mark - Notification
- (void)appLifecycleStateDidChange:(NSNotification *)sender {
    NSDictionary *userInfo = sender.userInfo;
    SAAppLifecycleState newState = [userInfo[kSAAppLifecycleNewStateKey] integerValue];
    SAAppLifecycleState oldState = [userInfo[kSAAppLifecycleOldStateKey] integerValue];

    if (![self isAutoTrackEnabled]) {
        return;
    }

    if (oldState == SAAppLifecycleStateInit) {
        // 触发冷启动事件或被动启动
        if (newState == SAAppLifecycleStateStartPassively) {
            [self.appStartTracker trackAppStartPassively];
        } else {
            [self.appStartTracker trackAppStartWithRelauch:NO];
        }

        [self.appEndTracker trackTimerStartAppEnd];
    } else if (newState == SAAppLifecycleStateStart) {
        // 触发热启动
        [self.appStartTracker trackAppStartWithRelauch:YES];
        [self.appEndTracker trackTimerStartAppEnd];
    } else if (newState == SAAppLifecycleStateEnd) {
        // 触发退出事件
        [self.appEndTracker trackAppEnd];
    }
}

- (void)remoteConfigModelChanged:(NSNotification *)sender {
    @try {
        self.disableSDK = [[sender.object valueForKey:@"disableSDK"] boolValue];
    } @catch(NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
}

#pragma mark - Public

- (BOOL)isAutoTrackEnabled {
    if ([SARemoteConfigManager sharedInstance].isDisableSDK) {
        SALogDebug(@"【remote config】SDK is disabled");
        return NO;
    }

    NSInteger autoTrackMode = [SARemoteConfigManager sharedInstance].autoTrackMode;
    if (autoTrackMode == kSAAutoTrackModeDefault) {
        // 远程配置不修改现有的 autoTrack 方式
        return (self.configOptions.autoTrackEventType != SensorsAnalyticsEventTypeNone);
    } else {
        // 远程配置修改现有的 autoTrack 方式
        BOOL isEnabled = (autoTrackMode != kSAAutoTrackModeDisabledAll);
        if (!isEnabled) {
            SALogDebug(@"【remote config】AutoTrack Event is ignored by remote config");
        }
        return isEnabled;
    }
}

- (BOOL)isAutoTrackEventTypeIgnored:(SensorsAnalyticsAutoTrackEventType)eventType {
    if ([SARemoteConfigManager sharedInstance].isDisableSDK) {
        SALogDebug(@"【remote config】SDK is disabled");
        return YES;
    }

    NSInteger autoTrackMode = [SARemoteConfigManager sharedInstance].autoTrackMode;
    if (autoTrackMode == kSAAutoTrackModeDefault) {
        // 远程配置不修改现有的 autoTrack 方式
        return !(self.configOptions.autoTrackEventType & eventType);
    } else {
        // 远程配置修改现有的 autoTrack 方式
        BOOL isIgnored = (autoTrackMode == kSAAutoTrackModeDisabledAll) ? YES : !(autoTrackMode & eventType);
        if (isIgnored) {
            NSString *ignoredEvent = @"None";
            switch (eventType) {
                case SensorsAnalyticsEventTypeAppStart:
                    ignoredEvent = SA_EVENT_NAME_APP_START;
                    break;

                case SensorsAnalyticsEventTypeAppEnd:
                    ignoredEvent = SA_EVENT_NAME_APP_END;
                    break;

                case SensorsAnalyticsEventTypeAppClick:
                    ignoredEvent = SA_EVENT_NAME_APP_CLICK;
                    break;

                case SensorsAnalyticsEventTypeAppViewScreen:
                    ignoredEvent = SA_EVENT_NAME_APP_VIEW_SCREEN;
                    break;

                default:
                    break;
            }
            SALogDebug(@"【remote config】%@ is ignored by remote config", ignoredEvent);
        }
        return isIgnored;
    }
}

#pragma mark - Private

#ifdef SENSORS_ANALYTICS_REACT_NATIVE
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

                [[SensorsAnalyticsSDK sharedInstance] trackAutoEvent:SA_EVENT_NAME_APP_CLICK properties:properties];
            }
        } @catch (NSException *exception) {
            SALogError(@"%@ error: %@", [SensorsAnalyticsSDK sharedInstance], exception);
        }
    });
}
#endif


@end

