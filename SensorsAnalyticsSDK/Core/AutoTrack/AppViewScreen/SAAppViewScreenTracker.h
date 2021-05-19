//
// SAAppViewScreenTracker.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/4/27.
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

#import <UIKit/UIKit.h>
#import "SAAppTrackerProtocol.h"
#import "SAConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAAppViewScreenTracker : NSObject <SAAppTrackerProtocol>

@property (nonatomic, assign, getter=isIgnored) BOOL ignored;

- (void)autoTrackWithViewController:(UIViewController *)viewController;
- (void)trackWithViewController:(UIViewController *)viewController properties:(NSDictionary<NSString *, id> * _Nullable)properties;
- (void)trackWithURL:(NSString *)url properties:(NSDictionary<NSString *, id> * _Nullable)properties;
- (void)trackLaunchedPassivelyViewScreen;

#pragma mark - Ignore

- (void)ignoreAutoTrackViewControllers:(NSArray<NSString *> *)controllers;
- (BOOL)isViewControllerIgnored:(UIViewController *)viewController;
- (BOOL)isViewControllerStringIgnored:(NSString *)viewControllerClassName;
- (BOOL)shouldTrackViewController:(UIViewController *)controller ofType:(SensorsAnalyticsAutoTrackEventType)type;

@end

NS_ASSUME_NONNULL_END
