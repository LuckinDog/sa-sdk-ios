//
// SAReachability.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/1/19.
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

#import "SAReachability.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import "SALog.h"

typedef NS_ENUM(NSInteger, SAReachabilityStatus) {
    SAReachabilityStatusUnknown = -1,
    SAReachabilityStatusNotReachable = 0,
    SAReachabilityStatusViaWiFi = 1,
    SAReachabilityStatusViaWWAN = 2,
};

typedef void (^SAReachabilityStatusCallback)(SAReachabilityStatus status);

static SAReachabilityStatus SAReachabilityStatusForFlags(SCNetworkReachabilityFlags flags) {
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
        // The target host is not reachable.
        return SAReachabilityStatusNotReachable;
    }

    SAReachabilityStatus returnValue = SAReachabilityStatusUnknown;

    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        /*
         If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
         */
        returnValue = SAReachabilityStatusViaWiFi;
    }

    if ((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0 ||
        (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0) {
        /*
         ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
         */

        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            /*
             ... and no [user] intervention is needed...
             */
            returnValue = SAReachabilityStatusViaWiFi;
        }
    }

    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
        /*
         ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
         */
        returnValue = SAReachabilityStatusViaWWAN;
    }

    return returnValue;
}

static void SAPostReachabilityStatusChange(SCNetworkReachabilityFlags flags, SAReachabilityStatusCallback block) {
    SAReachabilityStatus status = SAReachabilityStatusForFlags(flags);
    if (block) {
        block(status);
    }
}

static void SAReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    SAPostReachabilityStatusChange(flags, (__bridge SAReachabilityStatusCallback)info);
}

static const void * SAReachabilityRetainCallback(const void *info) {
    return Block_copy(info);
}

static void SAReachabilityReleaseCallback(const void *info) {
    if (info) {
        Block_release(info);
    }
}

@interface SAReachability ()

@property (readonly, nonatomic, assign) SCNetworkReachabilityRef networkReachability;
@property (readonly, nonatomic, strong) CTTelephonyNetworkInfo *networkInfo;
@property (atomic, assign) SAReachabilityStatus reachabilityStatus;

@end

@implementation SAReachability

#pragma mark - Life Cycle

+ (instancetype)sharedInstance {
    static SAReachability *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self reachabilityInstance];
    });

    return sharedInstance;
}

+ (instancetype)reachabilityInstance {
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000)
    struct sockaddr_in6 address;
    bzero(&address, sizeof(address));
    address.sin6_len = sizeof(address);
    address.sin6_family = AF_INET6;
#else
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
#endif

    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&address);
    SAReachability *reachabilityInstance = [[self alloc] initWithReachability:reachability];

    CFRelease(reachability);

    return reachabilityInstance;
}

- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability {
    self = [super init];
    if (self) {
        if (reachability != NULL) {
            _networkReachability = CFRetain(reachability);
        }
        _networkInfo = [[CTTelephonyNetworkInfo alloc] init];
        self.reachabilityStatus = SAReachabilityStatusUnknown;
    }
    return self;
}

- (void)dealloc {
    [self stopMonitoring];

    if (_networkReachability != NULL) {
        CFRelease(_networkReachability);
    }
}

#pragma mark - Public Methods

- (void)startMonitoring {
    [self stopMonitoring];

    if (!self.networkReachability) {
        return;
    }

    __weak __typeof(self) weakSelf = self;
    SAReachabilityStatusCallback callback = ^(SAReachabilityStatus status) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;

        strongSelf.reachabilityStatus = status;
    };

    // 设置网络状态变化的回调
    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, SAReachabilityRetainCallback, SAReachabilityReleaseCallback, NULL};
    SCNetworkReachabilitySetCallback(self.networkReachability, SAReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);

    // 获取网络状态
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(self.networkReachability, &flags)) {
        SAPostReachabilityStatusChange(flags, callback);
    }
}

- (void)stopMonitoring {
    if (!self.networkReachability) {
        return;
    }
    
    SCNetworkReachabilityUnscheduleFromRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}

- (SensorsAnalyticsNetworkType)networkTypeOptions {
    NSString *networkTypeString = self.networkTypeString;
    
    if ([@"NULL" isEqualToString:networkTypeString]) {
        return SensorsAnalyticsNetworkTypeNONE;
    } else if ([@"WIFI" isEqualToString:networkTypeString]) {
        return SensorsAnalyticsNetworkTypeWIFI;
    } else if ([@"2G" isEqualToString:networkTypeString]) {
        return SensorsAnalyticsNetworkType2G;
    } else if ([@"3G" isEqualToString:networkTypeString]) {
        return SensorsAnalyticsNetworkType3G;
    } else if ([@"4G" isEqualToString:networkTypeString]) {
        return SensorsAnalyticsNetworkType4G;
#ifdef __IPHONE_14_1
    } else if ([@"5G" isEqualToString:networkTypeString]) {
        return SensorsAnalyticsNetworkType5G;
#endif
    }
    
    return SensorsAnalyticsNetworkTypeUnknown;
}

- (NSString *)networkTypeString {
    @try {
        if (self.isReachableViaWiFi) {
            return @"WIFI";
        }
        
        if (self.isReachableViaWWAN) {
            NSString *currentRadioAccessTechnology = nil;
#ifdef __IPHONE_12_0
            if (@available(iOS 12.1, *)) {
                currentRadioAccessTechnology = self.networkInfo.serviceCurrentRadioAccessTechnology.allValues.lastObject;
            }
#endif
            // 测试发现存在少数 12.0 和 12.0.1 的机型 serviceCurrentRadioAccessTechnology 返回空
            if (!currentRadioAccessTechnology) {
                currentRadioAccessTechnology = self.networkInfo.currentRadioAccessTechnology;
            }
            
            return [self networkStatusWithRadioAccessTechnology:currentRadioAccessTechnology];
        }
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
    
    return @"NULL";
}

- (BOOL)isReachable {
    return [self isReachableViaWWAN] || [self isReachableViaWiFi];
}

- (BOOL)isReachableViaWWAN {
    return self.reachabilityStatus == SAReachabilityStatusViaWWAN;
}

- (BOOL)isReachableViaWiFi {
    return self.reachabilityStatus == SAReachabilityStatusViaWiFi;
}

#pragma mark – Private Methods

- (NSString *)networkStatusWithRadioAccessTechnology:(NSString *)value {
    if ([value isEqualToString:CTRadioAccessTechnologyGPRS] ||
        [value isEqualToString:CTRadioAccessTechnologyEdge]
        ) {
        return @"2G";
    } else if ([value isEqualToString:CTRadioAccessTechnologyWCDMA] ||
               [value isEqualToString:CTRadioAccessTechnologyHSDPA] ||
               [value isEqualToString:CTRadioAccessTechnologyHSUPA] ||
               [value isEqualToString:CTRadioAccessTechnologyCDMA1x] ||
               [value isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0] ||
               [value isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA] ||
               [value isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB] ||
               [value isEqualToString:CTRadioAccessTechnologyeHRPD]
               ) {
        return @"3G";
    } else if ([value isEqualToString:CTRadioAccessTechnologyLTE]) {
        return @"4G";
    }
#ifdef __IPHONE_14_1
    else if (@available(iOS 14.1, *)) {
        if ([value isEqualToString:CTRadioAccessTechnologyNRNSA] ||
            [value isEqualToString:CTRadioAccessTechnologyNR]
            ) {
            return @"5G";
        }
    }
#endif
    return @"UNKNOWN";
}

@end
