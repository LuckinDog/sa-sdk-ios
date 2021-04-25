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
#import "SARemoteConfigModel.h"
#import "SAModuleManager.h"
#import "SAAppLifecycle.h"
#import "SALog.h"
#import "UIApplication+AutoTrack.h"
#import "UIViewController+AutoTrack.h"
#import "SASwizzle.h"
#import "NSObject+DelegateProxy.h"
#import "SAAppStartTracker.h"
#import "SAAppEndTracker.h"
#import "SAConstants+Private.h"

@interface SAAutoTrackManager ()

@property (nonatomic, strong) SAAppStartTracker *appStartTracker;
@property (nonatomic, strong) SAAppEndTracker *appEndTracker;

@property (nonatomic, getter=isDisableSDK) BOOL disableSDK;
@property (nonatomic, assign) NSInteger autoTrackMode;

@end

@implementation SAAutoTrackManager

#pragma mark - SAModuleProtocol

- (instancetype)init {
    self = [super init];
    if (self) {
        _appStartTracker = [[SAAppStartTracker alloc] init];
        _appEndTracker = [[SAAppEndTracker alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleStateDidChange:) name:kSAAppLifecycleStateDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteConfigModelChanged:) name:SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

        //React Native
        if (NSClassFromString(@"RCTUIManager") && [SAModuleManager.sharedInstance contains:SAModuleTypeReactNative]) {
            [SAModuleManager.sharedInstance setEnable:YES forModuleType:SAModuleTypeReactNative];
        }
    });
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

    // 被动启动
    if (oldState == SAAppLifecycleStateInit && newState == SAAppLifecycleStateStartPassively) {
        self.appStartTracker.passively = YES;
        [self.appStartTracker trackEventWithProperties:SAModuleManager.sharedInstance.utmProperties];
        return;
    }

    // 冷（热）启动
    if (newState == SAAppLifecycleStateStart) {
        self.appStartTracker.passively = NO;
        [self.appStartTracker trackEventWithProperties:SAModuleManager.sharedInstance.utmProperties];

        // 启动 AppEnd 事件计时器
        [self.appEndTracker trackTimerStartAppEnd];
        return;
    }

    // 退出
    if (newState == SAAppLifecycleStateEnd) {
        [self.appEndTracker trackEventWithProperties:nil];
    }
}

- (void)remoteConfigModelChanged:(NSNotification *)sender {
    @try {
        self.disableSDK = [[sender.object valueForKey:@"disableSDK"] boolValue];
        self.autoTrackMode = [[sender.object valueForKey:@"autoTrackMode"] integerValue];

        [self updateAutoTrackEventType];
    } @catch(NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
}

#pragma mark - Public

- (BOOL)isAutoTrackEnabled {
    if (self.isDisableSDK) {
        SALogDebug(@"【remote config】SDK is disabled");
        return NO;
    }

    NSInteger autoTrackMode = self.autoTrackMode;
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
    if (self.isDisableSDK) {
        SALogDebug(@"【remote config】SDK is disabled");
        return YES;
    }

    NSInteger autoTrackMode = self.autoTrackMode;
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
                    ignoredEvent = [SAAppStartTracker eventName];
                    break;

                case SensorsAnalyticsEventTypeAppEnd:
                    ignoredEvent = [SAAppEndTracker eventName];
                    break;

                case SensorsAnalyticsEventTypeAppClick:
                    ignoredEvent = kSAEventNameAppClick;
                    break;

                case SensorsAnalyticsEventTypeAppViewScreen:
                    ignoredEvent = kSAEventNameAppViewScreen;
                    break;

                default:
                    break;
            }
            SALogDebug(@"【remote config】%@ is ignored by remote config", ignoredEvent);
        }
        return isIgnored;
    }
}

- (void)updateAutoTrackEventType {
    self.appStartTracker.ignored = [self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppStart];
    self.appEndTracker.ignored = [self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppEnd];
}

@end

