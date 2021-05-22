//
// SAAppTracker.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/5/20.
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

#import "SAAppTracker.h"
#import "SATrackEventObject.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SALog.h"
#import "SAConstants+Private.h"

@implementation SAAppTracker

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _ignored = NO;
        _passively = NO;
        _ignoredViewControllers = [NSMutableSet set];
    }
    return self;
}

#pragma mark - Public Methods

- (NSString *)eventName {
    return nil;
}

- (void)trackAutoTrackEventWithProperties:(NSDictionary *)properties {
    SAAutoTrackEventObject *object = [[SAAutoTrackEventObject alloc] initWithEventId:[self eventName]];
    [SensorsAnalyticsSDK.sharedInstance asyncTrackEventObject:object properties:properties];
}

- (BOOL)shouldTrackViewController:(UIViewController *)controller {
    if ([self isViewControllerIgnored:controller]) {
        return NO;
    }

    return ![self isBlackListViewController:controller];
}

- (void)ignoreAutoTrackViewControllers:(NSArray<NSString *> *)controllers {
    if (controllers == nil || controllers.count == 0) {
        return;
    }
    [self.ignoredViewControllers addObjectsFromArray:controllers];
}

- (BOOL)isViewControllerIgnored:(UIViewController *)viewController {
    if (viewController == nil) {
        return NO;
    }

    NSString *screenName = NSStringFromClass([viewController class]);
    return [self.ignoredViewControllers containsObject:screenName];
}

- (BOOL)isViewControllerStringIgnored:(NSString *)viewControllerClassName {
    if (viewControllerClassName == nil) {
        return NO;
    }

    return [self.ignoredViewControllers containsObject:viewControllerClassName];
}

- (BOOL)isBlackListViewController:(UIViewController *)viewController {
    static dispatch_once_t onceToken;
    static NSDictionary *allClasses = nil;
    dispatch_once(&onceToken, ^{
        NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[SensorsAnalyticsSDK class]] pathForResource:@"SensorsAnalyticsSDK" ofType:@"bundle"]];
        //文件路径
        NSString *jsonPath = [sensorsBundle pathForResource:@"sa_autotrack_viewcontroller_blacklist.json" ofType:nil];
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        @try {
            allClasses = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
        } @catch(NSException *exception) {  // json加载和解析可能失败
            SALogError(@"%@ error: %@", self, exception);
        }
    });

    NSString *eventName = [self eventName];
    NSDictionary *dictonary = allClasses[eventName];
    for (NSString *publicClass in dictonary[@"public"]) {
        if ([viewController isKindOfClass:NSClassFromString(publicClass)]) {
            return YES;
        }
    }
    return [(NSArray *)dictonary[@"private"] containsObject:NSStringFromClass(viewController.class)];
}

@end
