//
//  UIViewController.m
//  HookTest
//
//  Created by 王灼洲 on 2017/10/18.
//  Copyright © 2017年 wanda. All rights reserved.
//

#import "UIViewController+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"
#import "SASwizzle.h"
@implementation UIViewController (AutoTrack)
+(void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIViewController sa_swizzleMethod:@selector(viewWillAppear:) withMethod:@selector(sa_autotrack_viewWillAppear:) error:NULL];
    });
}

- (void)sa_autotrack_viewWillAppear:(BOOL)animated {
    @try {
        UIViewController *viewController = (UIViewController *)self;
        if (![[SensorsAnalyticsSDK sharedInstance]isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppViewScreen]) {
            [[SensorsAnalyticsSDK sharedInstance] trackViewScreen: viewController];
        }
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
    [self sa_autotrack_viewWillAppear:animated];
}
@end
