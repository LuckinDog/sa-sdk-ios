//
// SAAutoTrackManager.h
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

#import <Foundation/Foundation.h>
#import "SAConstants.h"
#import "SAAppStartTracker.h"
#import "SAAppEndTracker.h"
#import "SAModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class SAConfigOptions;

@interface SAAutoTrackManager : NSObject <SAModuleProtocol, SAAutoTrackModuleProtocol>

@property (nonatomic, strong) SAConfigOptions *configOptions;

@property (nonatomic, assign, getter=isEnable) BOOL enable;

@property (nonatomic, strong, readonly) SAAppStartTracker *appStartTracker;
@property (nonatomic, strong, readonly) SAAppEndTracker *appEndTracker;

+ (SAAutoTrackManager *)sharedInstance;

#pragma mark - Public
- (BOOL)isAutoTrackEnabled;
- (BOOL)isAutoTrackEventTypeIgnored:(SensorsAnalyticsAutoTrackEventType)eventType;

@end

NS_ASSUME_NONNULL_END
