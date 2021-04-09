//
// SAAppLifecycle.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/4/1.
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

#import "SAAppLifecycle.h"
#import "SACommonUtility.h"
#import "SALog.h"

NSNotificationName const kSAAppLifecycleStateDidChangeNotification = @"com.sensorsdata.SAAppLifecycleStateDidChange";
NSString * const kSAAppLifecycleNewStateKey = @"new";
NSString * const kSAAppLifecycleOldStateKey = @"old";

@interface SAAppLifecycle ()

@property (nonatomic, assign) SAAppLifecycleState state;

@end

@implementation SAAppLifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _state = SAAppLifecycleStateInit;

        [self setupListeners];
        [self setupLaunchedState];
    }
    return self;
}

- (void)setupLaunchedState {
    dispatch_block_t mainThreadBlock = ^(){
#if TARGET_OS_IPHONE
        BOOL isAppStateBackground = UIApplication.sharedApplication.applicationState == UIApplicationStateBackground;
#else
        BOOL isAppStateBackground = NO;
#endif
        self.state = isAppStateBackground ? SAAppLifecycleStateStartPassively : SAAppLifecycleStateStart;
    };

    // 被动启动时 iOS 13 以下异步主队列的 block 不会执行
    if (@available(iOS 13.0, *)) {
        dispatch_async(dispatch_get_main_queue(), mainThreadBlock);
    } else {
        [SACommonUtility performBlockOnMainThread:mainThreadBlock];
    }
}

#pragma mark - Setter

- (void)setState:(SAAppLifecycleState)state {
    if (_state == state) {
        return;
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    userInfo[kSAAppLifecycleNewStateKey] = @(state);
    if (_state >= SAAppLifecycleStateInit) {
        userInfo[kSAAppLifecycleOldStateKey] = @(_state);
    }

    _state = state;

    [NSNotificationCenter.defaultCenter postNotificationName:kSAAppLifecycleStateDidChangeNotification object:self userInfo:userInfo];
}

#pragma mark - Listener

- (void)setupListeners {
#if TARGET_OS_IPHONE
    // 监听 App 启动或结束事件
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
#endif
}

#if TARGET_OS_IPHONE
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    SALogDebug(@"%@ application did become active", self);

    self.state = SAAppLifecycleStateStart;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    SALogDebug(@"%@ application did enter background", self);

    self.state = SAAppLifecycleStateEnd;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    SALogDebug(@"applicationWillTerminateNotification");

    self.state = SAAppLifecycleStateTerminate;
}
#endif

@end

