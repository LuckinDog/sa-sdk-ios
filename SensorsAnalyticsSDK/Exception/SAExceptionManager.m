//
// SAExceptionManager.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/6/4.
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

#import "SAExceptionManager.h"
#import "SensorsAnalyticsSDK.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAModuleManager.h"
#import "SALog.h"

#include <libkern/OSAtomic.h>
#include <execinfo.h>

#ifdef SENSORS_ANALYTICS_CRASH_SLIDEADDRESS
#import <mach-o/dyld.h>
#endif

static NSString * const kSASignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
static NSString * const kSASignalKey = @"UncaughtExceptionHandlerSignalKey";

static volatile int32_t kSACount = 0;
static const int32_t kSAMaximum = 10;

static NSString * const kSAAppCrashedReason = @"app_crashed_reason";

@interface SensorsAnalyticsSDK()
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@end

@interface SAExceptionManager ()

@property (nonatomic) NSUncaughtExceptionHandler *defaultExceptionHandler;
@property (nonatomic, unsafe_unretained) struct sigaction *prev_signal_handlers;

@end

@implementation SAExceptionManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _prev_signal_handlers = calloc(NSIG, sizeof(struct sigaction));

        [self setupExceptionHandler];
    }
    return self;
}

- (void)dealloc {
    free(_prev_signal_handlers);
}

+ (instancetype)sharedInstance {
    return (SAExceptionManager *)[SAModuleManager.sharedInstance managerForModuleType:SAModuleTypeException];
}

- (void)setupExceptionHandler {
    _defaultExceptionHandler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(&SAHandleException);

    struct sigaction action;
    sigemptyset(&action.sa_mask);
    action.sa_flags = SA_SIGINFO;
    action.sa_sigaction = &SASignalHandler;
    int signals[] = {SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS};
    for (int i = 0; i < sizeof(signals) / sizeof(int); i++) {
        struct sigaction prev_action;
        int err = sigaction(signals[i], &action, &prev_action);
        if (err == 0) {
            char *address_action = (char *)&prev_action;
            char *address_signal = (char *)(_prev_signal_handlers + signals[i]);
            strlcpy(address_signal, address_action, sizeof(prev_action));
        } else {
            SALogError(@"Errored while trying to set up sigaction for signal %d", signals[i]);
        }
    }
}

#pragma mark - Handler

static void SASignalHandler(int crashSignal, struct __siginfo *info, void *context) {
    int32_t exceptionCount = OSAtomicIncrement32(&kSACount);
    if (exceptionCount <= kSAMaximum) {
        NSDictionary *userInfo = @{kSASignalKey: @(crashSignal)};
        NSString *reason;
        @try {
            reason = [NSString stringWithFormat:@"Signal %d was raised.", crashSignal];
        } @catch(NSException *exception) {
            //ignored
        }

        @try {
            NSException *exception = [NSException exceptionWithName:kSASignalExceptionName
                                                             reason:reason
                                                           userInfo:userInfo];

            [SAExceptionManager.sharedInstance handleUncaughtException:exception];
        } @catch(NSException *exception) {

        }
    }

    struct sigaction prev_action = SAExceptionManager.sharedInstance.prev_signal_handlers[crashSignal];
    if (prev_action.sa_flags & SA_SIGINFO) {
        if (prev_action.sa_sigaction) {
            prev_action.sa_sigaction(crashSignal, info, context);
        }
    } else if (prev_action.sa_handler &&
               prev_action.sa_handler != SIG_IGN) {
        // SIG_IGN 表示忽略信号
        prev_action.sa_handler(crashSignal);
    }
}

static void SAHandleException(NSException *exception) {
    int32_t exceptionCount = OSAtomicIncrement32(&kSACount);
    if (exceptionCount <= kSAMaximum) {
        [SAExceptionManager.sharedInstance handleUncaughtException:exception];
    }

    if (SAExceptionManager.sharedInstance.defaultExceptionHandler) {
        SAExceptionManager.sharedInstance.defaultExceptionHandler(exception);
    }
}

- (void)handleUncaughtException:(NSException *)exception {
    // Archive the values for each SensorsAnalytics instance
    @try {
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        if ([exception callStackSymbols]) {
            NSString *exceptionStack = [[exception callStackSymbols] componentsJoinedByString:@"\n"];

#ifdef SENSORS_ANALYTICS_CRASH_SLIDEADDRESS
            long slide_address = [SAExceptionManager computeImageSlide];
            properties[kSAAppCrashedReason] = [NSString stringWithFormat:@"Exception Reason:%@\nSlide_Address:%lx\nException Stack:%@", [exception reason], slide_address, exceptionStack];
#else
            properties[kSAAppCrashedReason] = [NSString stringWithFormat:@"Exception Reason:%@\nException Stack:%@", [exception reason], exceptionStack];
#endif
        } else {
            NSString *exceptionStack = [[NSThread callStackSymbols] componentsJoinedByString:@"\n"];
            properties[kSAAppCrashedReason] = [NSString stringWithFormat:@"%@ %@", [exception reason], exceptionStack];
        }
        SAPresetEventObject *object = [[SAPresetEventObject alloc] initWithEventId:kSAEventNameAppCrashed];
        [SensorsAnalyticsSDK.sharedInstance asyncTrackEventObject:object properties:properties];

        // 触发退出事件
        [SAModuleManager.sharedInstance trackAppEndWhenCrashed];

        // 阻塞当前线程，完成 serialQueue 中数据相关的任务
        sensorsdata_dispatch_safe_sync(SensorsAnalyticsSDK.sharedInstance.serialQueue, ^{});
        SALogError(@"Encountered an uncaught exception. All SensorsAnalytics instances were archived.");
    } @catch(NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }

    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
}

#ifdef SENSORS_ANALYTICS_CRASH_SLIDEADDRESS
/** 增加 crash slideAdress 采集支持
 *  @return the slide of this binary image
 */
+ (long)computeImageSlide {
    long slide = -1;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        if (_dyld_get_image_header(i)->filetype == MH_EXECUTE) {
            slide = _dyld_get_image_vmaddr_slide(i);
            break;
        }
    }
    return slide;
}
#endif

@end
