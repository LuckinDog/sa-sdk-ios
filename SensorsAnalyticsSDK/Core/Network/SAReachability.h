//  SASwizzler.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/20/16
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

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SAReachabilityStatus) {
    SAReachabilityStatusUnknown = -1,
    SAReachabilityStatusNotReachable = 0,
    SAReachabilityStatusViaWiFi = 1,
    SAReachabilityStatusViaWWAN = 2,
};

#pragma mark IPv6 Support
//Reachability fully support IPv6.  For full details, see ReadMe.md.

NS_ASSUME_NONNULL_BEGIN

@interface SAReachability : NSObject

/// 网络触达状态
@property (readonly, nonatomic, assign) SAReachabilityStatus reachabilityStatus;

/// 是否有网络连接
@property (readonly, nonatomic, assign, getter = isReachable) BOOL reachable;

/// 当前的网络状态是否为 WIFI
@property (readonly, nonatomic, assign, getter = isReachableViaWiFi) BOOL reachableViaWiFi;

/// 当前的网络状态是否为 WWAN
@property (readonly, nonatomic, assign, getter = isReachableViaWWAN) BOOL reachableViaWWAN;

/// 获取网络触达类的实例
+ (instancetype)sharedInstance;

/// 开始监听网络状态
- (void)startMonitoring;

/// 停止监听网络状态
- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END
