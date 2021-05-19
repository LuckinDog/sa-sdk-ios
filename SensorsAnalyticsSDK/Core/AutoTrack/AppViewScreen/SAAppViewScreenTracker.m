//
// SAAppViewScreenTracker.m
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAAppViewScreenTracker.h"
#import "SensorsAnalyticsSDK+SAAutoTrack.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "UIViewController+AutoTrack.h"
#import "SAAppLifecycle.h"
#import "SAConstants+Private.h"
#import "SAValidator.h"
#import "SAAutoTrackUtils.h"
#import "SALog.h"
#import "SAReferrerManager.h"
// TODO:wq 这里引用了 SAModuleManager
#import "SAModuleManager.h"

@interface SAAppViewScreenTracker ()

@property (nonatomic, strong) NSMutableArray<UIViewController *> *launchedPassivelyControllers;
// 用户设置的不被 AutoTrack 的 Controllers
@property (nonatomic, strong) NSMutableArray<NSString *> *ignoredViewControllers;

@end

@implementation SAAppViewScreenTracker

- (instancetype)init {
    self = [super init];
    if (self) {
        _launchedPassivelyControllers = [NSMutableArray array];
        _ignoredViewControllers = [NSMutableArray array];
    }
    return self;
}

#pragma mark - SAAppTrackerProtocol

+ (NSString *)eventName {
    return kSAEventNameAppViewScreen;
}

#pragma mark - Private

- (NSDictionary *)buildWithViewController:(UIViewController *)viewController properties:(NSDictionary<NSString *, id> *)properties autoTrack:(BOOL)autoTrack {
    NSMutableDictionary *eventProperties = [[NSMutableDictionary alloc] init];

    NSDictionary *autoTrackProperties = [SAAutoTrackUtils propertiesWithViewController:viewController];
    [eventProperties addEntriesFromDictionary:autoTrackProperties];

    if (autoTrack) {
        // App 通过 Deeplink 启动时第一个页面浏览事件会添加 utms 属性
        // 只需要处理全埋点的页面浏览事件
        [eventProperties addEntriesFromDictionary:SAModuleManager.sharedInstance.utmProperties];
        [SAModuleManager.sharedInstance clearUtmProperties];
    }

    if ([SAValidator isValidDictionary:properties]) {
        [eventProperties addEntriesFromDictionary:properties];
    }

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

#pragma mark - Track

- (void)autoTrackWithViewController:(UIViewController *)viewController {
    if (!viewController) {
        return;
    }
    //过滤用户设置的不被AutoTrack的Controllers
    if (![self shouldTrackViewController:viewController ofType:SensorsAnalyticsEventTypeAppViewScreen]) {
        return;
    }

    if (SensorsAnalyticsSDK.sharedInstance.lifecycleState == SAAppLifecycleStateStartPassively) {
        [self.launchedPassivelyControllers addObject:viewController];
        return;
    }

    NSDictionary *eventProperties = [self buildWithViewController:viewController properties:nil autoTrack:YES];
    SAAutoTrackEventObject *object = [[SAAutoTrackEventObject alloc] initWithEventId:kSAEventNameAppViewScreen];
    [SensorsAnalyticsSDK.sharedInstance asyncTrackEventObject:object properties:eventProperties];
}

- (void)trackWithViewController:(UIViewController *)viewController properties:(NSDictionary<NSString *, id> *)properties {
    if (!viewController) {
        return;
    }

    if ([self isBlackListViewController:viewController ofType:SensorsAnalyticsEventTypeAppViewScreen]) {
        return;
    }

    NSDictionary *eventProperties = [self buildWithViewController:viewController properties:properties autoTrack:NO];
    SAPresetEventObject *object  = [[SAPresetEventObject alloc] initWithEventId:kSAEventNameAppViewScreen];
    [SensorsAnalyticsSDK.sharedInstance asyncTrackEventObject:object properties:eventProperties];
}

- (void)trackWithURL:(NSString *)url properties:(NSDictionary<NSString *,id> *)properties {
    NSDictionary *eventProperties = [[SAReferrerManager sharedInstance] propertiesWithURL:url eventProperties:properties];

    SAPresetEventObject *object  = [[SAPresetEventObject alloc] initWithEventId:kSAEventNameAppViewScreen];
    [SensorsAnalyticsSDK.sharedInstance asyncTrackEventObject:object properties:eventProperties];
}

- (void)trackLaunchedPassivelyViewScreen {
    if (self.launchedPassivelyControllers.count == 0) {
        return;
    }

    for (UIViewController *vc in self.launchedPassivelyControllers) {
        [self autoTrackWithViewController:vc];
    }
    self.launchedPassivelyControllers = [NSMutableArray array];
}

#pragma mark - Ignore

- (void)ignoreAutoTrackViewControllers:(NSArray<NSString *> *)controllers {
    if (controllers == nil || controllers.count == 0) {
        return;
    }
    [_ignoredViewControllers addObjectsFromArray:controllers];

    //去重
    NSSet *set = [NSSet setWithArray:_ignoredViewControllers];
    if (set != nil) {
        _ignoredViewControllers = [NSMutableArray arrayWithArray:[set allObjects]];
    } else {
        _ignoredViewControllers = [[NSMutableArray alloc] init];
    }
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

#pragma mark - Private

- (BOOL)shouldTrackViewController:(UIViewController *)controller ofType:(SensorsAnalyticsAutoTrackEventType)type {
    if ([self isViewControllerIgnored:controller]) {
        return NO;
    }

    return ![self isBlackListViewController:controller ofType:type];
}

- (BOOL)isBlackListViewController:(UIViewController *)viewController ofType:(SensorsAnalyticsAutoTrackEventType)type {
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

    NSDictionary *dictonary = (type == SensorsAnalyticsEventTypeAppViewScreen) ? allClasses[kSAEventNameAppViewScreen] : allClasses[kSAEventNameAppClick];
    for (NSString *publicClass in dictonary[@"public"]) {
        if ([viewController isKindOfClass:NSClassFromString(publicClass)]) {
            return YES;
        }
    }
    return [(NSArray *)dictonary[@"private"] containsObject:NSStringFromClass(viewController.class)];
}


@end
