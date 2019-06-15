//
//  UIViewController+AutoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/10/18.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "UIViewController+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "SAConstants+Private.h"
#import "SALogger.h"
#import "SASwizzler.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "UIView+AutoTrack.h"
#import "SAAutoTrackUtils.h"

@implementation UIViewController (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    return [[SensorsAnalyticsSDK sharedInstance] shouldTrackViewController:self ofType:SensorsAnalyticsEventTypeAppClick];
}

- (NSString *)sensorsdata_screenName {
    return NSStringFromClass([self class]);
}

- (NSString *)sensorsdata_title {
    NSString *titleViewContent = self.navigationItem.titleView.sensorsdata_elementContent;
    if (titleViewContent.length > 0) {
        return titleViewContent;
    }
    NSString *controllerTitle = self.navigationItem.title;
    if (controllerTitle.length > 0) {
        return controllerTitle;
    }
    return nil;
}

- (NSString *)sensorsdata_itemPath {
    return [SAAutoTrackUtils itemPathForResponder:self];
}

- (void)sa_autotrack_viewWillAppear:(BOOL)animated {
    @try {
        
        if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppViewScreen] == NO) {
#ifndef SENSORS_ANALYTICS_ENABLE_AUTOTRACK_CHILD_VIEWSCREEN
            UIViewController *viewController = (UIViewController *)self;
            if (![viewController.parentViewController isKindOfClass:[UIViewController class]] ||
                [viewController.parentViewController isKindOfClass:[UITabBarController class]] ||
                [viewController.parentViewController isKindOfClass:[UINavigationController class]] ||
                [viewController.parentViewController isKindOfClass:[UIPageViewController class]] ||
                [viewController.parentViewController isKindOfClass:[UISplitViewController class]]) {
                [[SensorsAnalyticsSDK sharedInstance] autoTrackViewScreen: viewController];
            }
#else
            [[SensorsAnalyticsSDK sharedInstance] autoTrackViewScreen:self];
#endif
        }
#ifndef SENSORS_ANALYTICS_ENABLE_AUTOTRACK_DIDSELECTROW
        if ([SensorsAnalyticsSDK.sharedInstance isAutoTrackEventTypeIgnored: SensorsAnalyticsEventTypeAppClick] == NO) {
            //UITableView
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UITABLEVIEW
            void (^tableViewBlock)(id, SEL, id, id) = ^(id view, SEL command, UITableView *tableView, NSIndexPath *indexPath) {
                NSMutableDictionary *properties = [[SAAutoTrackUtils propertiesWithAutoTrackObject:(UITableView<SAAutoTrackViewProperty> *)tableView didSelectedAtIndexPath:indexPath] mutableCopy];
                if (!properties) {
                    return;
                }
                @try {
                    if ([tableView.sensorsAnalyticsDelegate conformsToProtocol:@protocol(SAUIViewAutoTrackDelegate)] && [tableView.sensorsAnalyticsDelegate respondsToSelector:@selector(sensorsAnalytics_tableView:autoTrackPropertiesAtIndexPath:)]) {
                        [properties addEntriesFromDictionary:[tableView.sensorsAnalyticsDelegate sensorsAnalytics_tableView:tableView autoTrackPropertiesAtIndexPath:indexPath]];
                    }
                } @catch (NSException *exception) {
                    SAError(@"%@ error: %@", self, exception);
                }

                [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
            };
            if ([self respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
                [SASwizzler swizzleSelector:@selector(tableView:didSelectRowAtIndexPath:) onClass:self.class withBlock:tableViewBlock named:[NSString stringWithFormat:@"%@_%@", NSStringFromClass(self.class), @"UITableView_AutoTrack"]];
            }
#endif
            
            //UICollectionView
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UICOLLECTIONVIEW
            void (^collectionViewBlock)(id, SEL, id, id) = ^(id view, SEL command, UICollectionView *collectionView, NSIndexPath *indexPath) {
                NSMutableDictionary *properties = [[SAAutoTrackUtils propertiesWithAutoTrackObject:(UICollectionView<SAAutoTrackViewProperty> *)collectionView didSelectedAtIndexPath:indexPath] mutableCopy];
                if (!properties) {
                    return;
                }
                @try {
                    if ([collectionView.sensorsAnalyticsDelegate conformsToProtocol:@protocol(SAUIViewAutoTrackDelegate)] && [collectionView.sensorsAnalyticsDelegate respondsToSelector:@selector(sensorsAnalytics_collectionView:autoTrackPropertiesAtIndexPath:)]) {
                        [properties addEntriesFromDictionary:[collectionView.sensorsAnalyticsDelegate sensorsAnalytics_collectionView:collectionView autoTrackPropertiesAtIndexPath:indexPath]];
                    }
                } @catch (NSException *exception) {
                    SAError(@"%@ error: %@", self, exception);
                }

                [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
            };
            if ([self respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
                [SASwizzler swizzleSelector:@selector(collectionView:didSelectItemAtIndexPath:) onClass:self.class withBlock:collectionViewBlock named:[NSString stringWithFormat:@"%@_%@", NSStringFromClass(self.class), @"UICollectionView_AutoTrack"]];
            }
#endif
        }
#endif
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
    [self sa_autotrack_viewWillAppear:animated];
}
@end
