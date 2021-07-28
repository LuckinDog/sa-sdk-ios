//
// SAAppPageLeaveTracker.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/7/19.
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

#import "SAAppPageLeaveTracker.h"
#import "SAAutoTrackUtils.h"
#import "SAReferrerManager.h"
#import "SensorsAnalyticsSDK+SAAutoTrack.h"
#import "SAConstants+Private.h"
#import "SAConstants+Private.h"
#import "SAAppLifecycle.h"
#import "SensorsAnalyticsSDK+Private.h"

@implementation SAAppPageLeaveTracker

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleStateDidChange:) name:kSAAppLifecycleStateDidChangeNotification object:nil];
    }
    return self;
}

- (NSString *)eventId {
    return kSAEventNameAppPageLeave;
}

- (void)trackEvents {
    [self.timestamp enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
        NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
        NSNumber *timestamp = obj[kSAPageLeaveTimestamp];
        NSTimeInterval startTimestamp = [timestamp doubleValue];
        NSMutableDictionary *tempProperties = [[NSMutableDictionary alloc] initWithDictionary:obj[kSAPageLeaveAutoTrackProperties]];
        tempProperties[kSAEventDurationProperty] = @([[NSString stringWithFormat:@"%.3f", currentTimestamp - startTimestamp] floatValue]);
        [self trackWithProperties:[tempProperties copy]];
    }];
}

- (void)trackPageStart:(UIViewController *)viewController {
    if (![self shouldTrackViewController:viewController]) {
        return;
    }
    NSString *address = [NSString stringWithFormat:@"%p", viewController];
    if (self.timestamp[address]) {
        return;
    }
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[kSAPageLeaveTimestamp] = @([[NSDate date] timeIntervalSince1970]);
    properties[kSAPageLeaveAutoTrackProperties] = [self propertiesWithViewController:viewController];
    self.timestamp[address] = properties;
}

- (void)trackPageEnd:(UIViewController *)viewController {
    if (![self shouldTrackViewController:viewController]) {
        return;
    }
    NSString *address = [NSString stringWithFormat:@"%p", viewController];
    if (self.timestamp[address]) {
        NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
        NSMutableDictionary *properties = self.timestamp[address];
        NSNumber *timestamp = properties[kSAPageLeaveTimestamp];
        NSTimeInterval startTimestamp = [timestamp doubleValue];
        NSMutableDictionary *tempProperties = [[NSMutableDictionary alloc] initWithDictionary:properties[kSAPageLeaveAutoTrackProperties]];
        tempProperties[kSAEventDurationProperty] = @([[NSString stringWithFormat:@"%.3f", currentTimestamp - startTimestamp] floatValue]);
        [self trackWithProperties:[tempProperties copy]];
        self.timestamp[address] = nil;
    } else {
        [self trackWithProperties:[self propertiesWithViewController:viewController]];
    }
}

- (void)trackWithProperties:(NSDictionary *)properties {
    SAPresetEventObject *object = [[SAPresetEventObject alloc] initWithEventId:kSAEventNameAppPageLeave];
    [SensorsAnalyticsSDK.sharedInstance asyncTrackEventObject:object properties:properties];
}

- (void)appLifecycleStateDidChange:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    SAAppLifecycleState newState = [userInfo[kSAAppLifecycleNewStateKey] integerValue];
    // 冷（热）启动
    if (newState == SAAppLifecycleStateStart) {
        [self.timestamp enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
            obj[kSAPageLeaveTimestamp] = @([[NSDate date] timeIntervalSince1970]);
        }];
        return;
    }

    // 退出
    if (newState == SAAppLifecycleStateEnd) {
        [self trackEvents];
    }
}

- (NSDictionary *)propertiesWithViewController:(UIViewController<SAAutoTrackViewControllerProperty> *)viewController {
    NSMutableDictionary *eventProperties = [[NSMutableDictionary alloc] init];
    NSDictionary *autoTrackProperties = [SAAutoTrackUtils propertiesWithViewController:viewController];
    [eventProperties addEntriesFromDictionary:autoTrackProperties];

    NSString *currentURL;
    if ([viewController conformsToProtocol:@protocol(SAScreenAutoTracker)] && [viewController respondsToSelector:@selector(getScreenUrl)]) {
        UIViewController<SAScreenAutoTracker> *screenAutoTrackerController = (UIViewController<SAScreenAutoTracker> *)viewController;
        currentURL = [screenAutoTrackerController getScreenUrl];
    }
    currentURL = [currentURL isKindOfClass:NSString.class] ? currentURL : NSStringFromClass(viewController.class);

    // 添加 $url 和 $referrer 页面浏览相关属性
    NSDictionary *newProperties = [SAReferrerManager.sharedInstance propertiesWithURL:currentURL eventProperties:eventProperties];

    return newProperties;
}

- (BOOL)shouldTrackViewController:(UIViewController *)viewController {
    NSDictionary *autoTrackBlackList = [self autoTrackViewControllerBlackList];
    NSDictionary *appViewScreenBlackList = autoTrackBlackList[kSAEventNameAppViewScreen];
    return ![self isViewController:viewController inBlackList:appViewScreenBlackList];
}

- (NSMutableDictionary<NSString *,NSMutableDictionary *> *)timestamp {
    if (!_timestamp) {
        _timestamp = [[NSMutableDictionary alloc] init];
    }
    return _timestamp;
}

@end
