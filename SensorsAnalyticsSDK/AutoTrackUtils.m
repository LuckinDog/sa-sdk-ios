//
//  AutoTrackUtils.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/6/29.
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


#import "AutoTrackUtils.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"
#import "UIView+SAHelpers.h"
#import "UIView+AutoTrack.h"
#import "SAConstants.h"
#import "SensorsAnalyticsSDK+Private.h"

@implementation AutoTrackUtils

+ (void)sa_find_view_responder:(UIView *)view withViewPathArray:(NSMutableArray *)viewPathArray {
    NSMutableArray *viewVarArray = [[NSMutableArray alloc] init];
    NSString *varE = [view jjf_varE];
    if (varE != nil) {
        [viewVarArray addObject:[NSString stringWithFormat:@"jjf_varE='%@'", varE]];
    }
    //    NSArray *varD = [view jjf_varSetD];
    //    if (varD != nil && [varD count] > 0) {
    //        [viewVarArray addObject:[NSString stringWithFormat:@"jjf_varSetD='%@'", [varD componentsJoinedByString:@","]]];
    //    }
    varE = [view jjf_varC];
    if (varE != nil) {
        [viewVarArray addObject:[NSString stringWithFormat:@"jjf_varC='%@'", varE]];
    }
    varE = [view jjf_varB];
    if (varE != nil) {
        [viewVarArray addObject:[NSString stringWithFormat:@"jjf_varB='%@'", varE]];
    }
    varE = [view jjf_varA];
    if (varE != nil) {
        [viewVarArray addObject:[NSString stringWithFormat:@"jjf_varA='%@'", varE]];
    }
    if ([viewVarArray count] == 0) {
        NSArray<__kindof UIView *> *subviews;
        NSMutableArray<__kindof UIView *> *sameTypeViews = [[NSMutableArray alloc] init];
        id nextResponder = [view nextResponder];
        if (nextResponder) {
            if ([nextResponder respondsToSelector:NSSelectorFromString(@"subviews")]) {
                subviews = [nextResponder subviews];
                if ([view isKindOfClass:[UITableView class]] || [view isKindOfClass:[UICollectionView class]]) {
                    subviews =  [[subviews reverseObjectEnumerator] allObjects];
                }
            }

            for (UIView *v in subviews) {
                if (v) {
                    if ([NSStringFromClass([view class]) isEqualToString:NSStringFromClass([v class])]) {
                        [sameTypeViews addObject:v];
                    }
                }
            }
        }
        if (sameTypeViews.count > 1) {
            NSString * className = nil;
            NSUInteger index = [sameTypeViews indexOfObject:view];
            className = [NSString stringWithFormat:@"%@[%lu]", NSStringFromClass([view class]), (unsigned long)index];
            [viewPathArray addObject:className];
        } else {
            [viewPathArray addObject:NSStringFromClass([view class])];
        }
    } else {
        NSString *viewIdentify = [NSString stringWithString:NSStringFromClass([view class])];
        viewIdentify = [viewIdentify stringByAppendingString:@"[("];
        for (int i = 0; i < viewVarArray.count; i++) {
            viewIdentify = [viewIdentify stringByAppendingString:viewVarArray[i]];
            if (i != (viewVarArray.count - 1)) {
                viewIdentify = [viewIdentify stringByAppendingString:@" AND "];
            }
        }
        viewIdentify = [viewIdentify stringByAppendingString:@")]"];
        [viewPathArray addObject:viewIdentify];
    }
}

+ (void)sa_find_responder:(id)responder withViewPathArray:(NSMutableArray *)viewPathArray {

    while (responder!=nil&&![responder isKindOfClass:[UIViewController class]] &&
           ![responder isKindOfClass:[UIWindow class]]) {
        long count = 0;
        NSArray<__kindof UIView *> *subviews;
        id nextResponder = [responder nextResponder];
        if (nextResponder) {
            if ([nextResponder respondsToSelector:NSSelectorFromString(@"subviews")]) {
                subviews = [nextResponder subviews];
                if ([responder isKindOfClass:[UITableView class]] || [responder isKindOfClass:[UICollectionView class]]) {
                    subviews =  [[subviews reverseObjectEnumerator] allObjects];
                }
                if (subviews) {
                    count = (unsigned long)subviews.count;
                }
            }
        }
        if (count <= 1) {
            if (NSStringFromClass([responder class])) {
                [viewPathArray addObject:NSStringFromClass([responder class])];
            }
        } else {
            NSMutableArray<__kindof UIView *> *sameTypeViews = [[NSMutableArray alloc] init];
            for (UIView *v in subviews) {
                if (v) {
                    if ([NSStringFromClass([responder class]) isEqualToString:NSStringFromClass([v class])]) {
                        [sameTypeViews addObject:v];
                    }
                }
            }
            if (sameTypeViews.count > 1) {
                NSString * className = nil;
                NSUInteger index = [sameTypeViews indexOfObject:responder];
                className = [NSString stringWithFormat:@"%@[%lu]", NSStringFromClass([responder class]), (unsigned long)index];
                [viewPathArray addObject:className];
            } else {
                [viewPathArray addObject:NSStringFromClass([responder class])];
            }
        }
        
        responder = [responder nextResponder];
    }
    
    if (responder && [responder isKindOfClass:[UIViewController class]]) {
        while ([responder parentViewController]) {
            UIViewController *viewController = [responder parentViewController];
            if (viewController) {
                NSArray<__kindof UIViewController *> *childViewControllers = [viewController childViewControllers];
                if (childViewControllers > 0) {
                    NSMutableArray<__kindof UIViewController *> *items = [[NSMutableArray alloc] init];
                    for (UIViewController *v in childViewControllers) {
                        if (v) {
                            if ([NSStringFromClass([responder class]) isEqualToString:NSStringFromClass([v class])]) {
                                [items addObject:v];
                            }
                        }
                    }
                    if (items.count > 1) {
                        NSString * className = nil;
                        NSUInteger index = [items indexOfObject:responder];
                        className = [NSString stringWithFormat:@"%@[%lu]", NSStringFromClass([responder class]), (unsigned long)index];
                        [viewPathArray addObject:className];
                    } else {
                        [viewPathArray addObject:NSStringFromClass([responder class])];
                    }
                } else {
                    [viewPathArray addObject:NSStringFromClass([responder class])];
                }
                
                responder = viewController;
            }
        }
        [viewPathArray addObject:NSStringFromClass([responder class])];
    }
}

+ (NSString *)contentFromView:(UIView *)rootView {
    
    @try {
        
        if (rootView.isHidden || rootView.sensorsAnalyticsIgnoreView) {
            return nil;
        }
        
        NSMutableString *elementContent = [NSMutableString string];
        
        NSString *currentTitle = rootView.sa_elementContent;
        if (currentTitle.length > 0) {
            [elementContent appendString:currentTitle];
            
        } else if ([rootView isKindOfClass:NSClassFromString(@"RTLabel")]) {//RTLabel:https://github.com/honcheng/RTLabel
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            if ([rootView respondsToSelector:NSSelectorFromString(@"text")]) {
                NSString *title = [rootView performSelector:NSSelectorFromString(@"text")];
                if (title.length > 0) {
                    [elementContent appendString:title];
                }
            }
#pragma clang diagnostic pop
        } else if ([rootView isKindOfClass:NSClassFromString(@"YYLabel")]) {//RTLabel:https://github.com/ibireme/YYKit
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            if ([rootView respondsToSelector:NSSelectorFromString(@"text")]) {
                NSString *title = [rootView performSelector:NSSelectorFromString(@"text")];
                if (title.length > 0) {
                    [elementContent appendString:title];
                }
            }
#pragma clang diagnostic pop
        }
#if (defined SENSORS_ANALYTICS_ENABLE_NO_PUBLICK_APIS)
        else if ([rootView isKindOfClass:[NSClassFromString(@"UITableViewCellContentView") class]] ||
                 [rootView isKindOfClass:[NSClassFromString(@"UICollectionViewCellContentView") class]] ||
                 rootView.subviews.count > 0) {
            
            NSMutableArray<NSString *> *elementContentArray = [NSMutableArray array];
            
            for (UIView *subView in rootView.subviews) {
                NSString *temp = [self contentFromView:subView];
                if (temp.length > 0) {
                    [elementContentArray addObject:temp];
                }
            }
            if (elementContentArray.count > 0) {
                [elementContent appendString:[elementContentArray componentsJoinedByString:@"-"]];
            };
        }
#else
        else {
            NSMutableArray<NSString *> *elementContentArray = [NSMutableArray array];
            
            for (UIView *subview in rootView.subviews) {
                NSString *temp = [self contentFromView:subview];
                if (temp.length > 0) {
                    [elementContentArray addObject:temp];
                }
            }
            if (elementContentArray.count > 0) {
                [elementContent appendString:[elementContentArray componentsJoinedByString:@"-"]];
            }
            
        }
#endif
        
        return [elementContent copy];
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
        return nil;
    }
}

+ (NSString *)titleFromViewController:(UIViewController *)viewController {
    if (!viewController) {
        return nil;
    }
    
    // 先获取 controller.navigationItem.title
    NSString *controllerTitle = viewController.navigationItem.title;
    
    // 再获取 controller.navigationItem.titleView, 并且优先级比较高
    UIView *titleView = viewController.navigationItem.titleView;

    NSString *elementContent = nil;
    if (titleView) {
        elementContent = [AutoTrackUtils contentFromView:titleView];
    }
    
    if (elementContent.length > 0) {
        return elementContent;
    }else {
        return controllerTitle;
    }
}

+ (void)trackAppClickWithUICollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    @try {
        //关闭 AutoTrack
        if (![[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled]) {
            return;
        }

        //忽略 $AppClick 事件
        if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
            return;
        }

        if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UICollectionView class]]) {
            return;
        }

        if (!collectionView) {
            return;
        }

        UIView *view = (UIView *)collectionView;
        if (!view) {
            return;
        }

        if (view.sensorsAnalyticsIgnoreView) {
            return;
        }

        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];

        [properties setValue:@"UICollectionView" forKey:SA_EVENT_PROPERTY_ELEMENT_TYPE];

        //ViewID
        if (view.sensorsAnalyticsViewID != nil) {
            [properties setValue:view.sensorsAnalyticsViewID forKey:SA_EVENT_PROPERTY_ELEMENT_ID];
        }

        UIViewController *viewController = [view sensorsAnalyticsViewController];

        if (viewController == nil || [viewController isKindOfClass:UINavigationController.class]) {
            viewController = [[SensorsAnalyticsSDK sharedInstance] currentViewController];
        }

        if (viewController != nil) {
            if ([[SensorsAnalyticsSDK sharedInstance] isViewControllerIgnored:viewController]) {
                return;
            }

            //获取 Controller 名称($screen_name)
            NSString *screenName = NSStringFromClass([viewController class]);
            [properties setValue:screenName forKey:SA_EVENT_PROPERTY_SCREEN_NAME];

            NSString *controllerTitle = [AutoTrackUtils titleFromViewController:viewController];
            if (controllerTitle) {
                [properties setValue:controllerTitle forKey:SA_EVENT_PROPERTY_TITLE];
            }
        }

        if (indexPath) {
            [properties setValue:[NSString stringWithFormat: @"%ld:%ld", (unsigned long)indexPath.section,(unsigned long)indexPath.row] forKey:SA_EVENT_PROPERTY_ELEMENT_POSITION];
        }

        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        if (cell==nil) {
            [collectionView layoutIfNeeded];
            cell = [collectionView cellForItemAtIndexPath:indexPath];
        }
        NSString *cellClass =NSStringFromClass([cell class]);
        
        if ([[SensorsAnalyticsSDK sharedInstance] isHeatMapEnabled] && [[SensorsAnalyticsSDK sharedInstance] isHeatMapViewController:viewController]) {
            NSMutableArray *viewPathArray = [[NSMutableArray alloc] init];
            long section = (unsigned long)indexPath.section;
            int count = 0;
            for (int i = 0; i <= section; i++) {
                NSInteger numberOfItemsInSection = [collectionView numberOfItemsInSection:i];
                if (i == section) {
                    numberOfItemsInSection = indexPath.row;
                }
                for (int j = 0; j < numberOfItemsInSection; j++) {
                    UICollectionViewCell *cellRow = [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i]];
                    if(cellRow == nil) {
                        [collectionView layoutIfNeeded];
                        cellRow = [collectionView cellForItemAtIndexPath:indexPath];
                    }
                    if(cellRow == nil) {
                        [collectionView reloadData];
                        [collectionView layoutIfNeeded];
                        cellRow = [collectionView cellForItemAtIndexPath:indexPath];
                    }
                    if ([cellClass isEqualToString:NSStringFromClass([cellRow class])]) {
                        count++;
                    }
                }
            }
            [viewPathArray addObject:[NSString stringWithFormat:@"%@[%d]",NSStringFromClass([cell class]), count]];
            id responder = cell.nextResponder;
            
            NSArray<__kindof UIView *> *subviews = [collectionView.superview subviews];
            NSMutableArray<__kindof UIView *> *viewsArray = [[NSMutableArray alloc] init];
            for (UIView *obj in subviews) {
                if ([NSStringFromClass([responder class]) isEqualToString:NSStringFromClass([obj class])]) {
                    [viewsArray addObject:obj];
                }
            }
            
            if ([viewsArray count] == 1) {
                [viewPathArray addObject:NSStringFromClass([responder class])];
            } else {
                NSUInteger index = [viewsArray indexOfObject:collectionView];
                [viewPathArray addObject:[NSString stringWithFormat:@"%@[%lu]", NSStringFromClass([responder class]), (unsigned long)index]];
            }
            
            responder = [responder nextResponder];
            [self sa_find_responder:responder withViewPathArray:viewPathArray];

            NSArray *array = [[viewPathArray reverseObjectEnumerator] allObjects];

            NSString *viewPath = [[NSString alloc] init];
            for (int i = 0; i < array.count; i++) {
                viewPath = [viewPath stringByAppendingString:array[i]];
                if (i != (array.count - 1)) {
                    viewPath = [viewPath stringByAppendingString:@"/"];
                }
            }
            [properties setValue:viewPath forKey:SA_EVENT_PROPERTY_ELEMENT_SELECTOR];
        }
        
        NSString *elementContent = [self contentFromView:cell];
        if (elementContent.length > 0) {
            [properties setValue:elementContent forKey:SA_EVENT_PROPERTY_ELEMENT_CONTENT];
        }

        //View Properties
        NSDictionary* propDict = view.sensorsAnalyticsViewProperties;
        if (propDict != nil) {
            [properties addEntriesFromDictionary:propDict];
        }

        @try {
            if (view.sensorsAnalyticsDelegate) {
                if ([view.sensorsAnalyticsDelegate conformsToProtocol:@protocol(SAUIViewAutoTrackDelegate)] && [view.sensorsAnalyticsDelegate respondsToSelector:@selector(sensorsAnalytics_collectionView:autoTrackPropertiesAtIndexPath:)]) {
                        [properties addEntriesFromDictionary:[view.sensorsAnalyticsDelegate sensorsAnalytics_collectionView:collectionView autoTrackPropertiesAtIndexPath:indexPath]];
                }
            }
        } @catch (NSException *exception) {
            SAError(@"%@ error: %@", self, exception);
        }

        [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

+ (void)trackAppClickWithUITableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    @try {
        //关闭 AutoTrack
        if (![[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled]) {
            return;
        }

        //忽略 $AppClick 事件
        if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
            return;
        }

        if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UITableView class]]) {
            return;
        }

        if (!tableView) {
            return;
        }

        UIView *view = (UIView *)tableView;
        if (!view) {
            return;
        }

        if (view.sensorsAnalyticsIgnoreView) {
            return;
        }

        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];

        [properties setValue:@"UITableView" forKey:SA_EVENT_PROPERTY_ELEMENT_TYPE];

        //ViewID
        if (view.sensorsAnalyticsViewID != nil) {
            [properties setValue:view.sensorsAnalyticsViewID forKey:SA_EVENT_PROPERTY_ELEMENT_ID];
        }

        UIViewController *viewController = [tableView sensorsAnalyticsViewController];

        if (viewController == nil || [viewController isKindOfClass:UINavigationController.class]) {
            viewController = [[SensorsAnalyticsSDK sharedInstance] currentViewController];
        }

        if (viewController != nil) {
            if ([[SensorsAnalyticsSDK sharedInstance] isViewControllerIgnored:viewController]) {
                return;
            }

            //获取 Controller 名称($screen_name)
            NSString *screenName = NSStringFromClass([viewController class]);
            [properties setValue:screenName forKey:SA_EVENT_PROPERTY_SCREEN_NAME];

            NSString *controllerTitle = [AutoTrackUtils titleFromViewController:viewController];
            if (controllerTitle) {
                [properties setValue:controllerTitle forKey:SA_EVENT_PROPERTY_TITLE];
            }
        }

        if (indexPath) {
            [properties setValue:[NSString stringWithFormat: @"%ld:%ld", (unsigned long)indexPath.section,(unsigned long)indexPath.row] forKey:SA_EVENT_PROPERTY_ELEMENT_POSITION];
        }

        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell == nil) {
            [tableView layoutIfNeeded];
            cell = [tableView cellForRowAtIndexPath:indexPath];
        }
        NSString *cellClass =NSStringFromClass([cell class]);
        NSString *elementContent = [[NSString alloc] init];

        if ([[SensorsAnalyticsSDK sharedInstance] isHeatMapEnabled] && [[SensorsAnalyticsSDK sharedInstance] isHeatMapViewController:viewController]) {
            NSMutableArray *viewPathArray = [[NSMutableArray alloc] init];
            long section = (unsigned long)indexPath.section;
            int count = 0;
            for (int i = 0; i <= section; i++) {
                NSInteger numberOfItemsInSection = [tableView numberOfRowsInSection:i];
                if (i == section) {
                    numberOfItemsInSection = indexPath.row;
                }
                for (int j = 0; j < numberOfItemsInSection; j++) {
                    UITableViewCell *cellRow = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i]];
                    if(cellRow == nil) {
                        [tableView layoutIfNeeded];
                        cellRow = [tableView cellForRowAtIndexPath:indexPath];
                    }
                    if(cellRow == nil) {
                        [tableView reloadData];
                        [tableView layoutIfNeeded];
                        cellRow = [tableView cellForRowAtIndexPath:indexPath];
                    }
                    if ([cellClass isEqualToString:NSStringFromClass([cellRow class])]) {
                        count++;
                    }
                }
            }
            [viewPathArray addObject:[NSString stringWithFormat:@"%@[%d]",NSStringFromClass([cell class]), count]];
            id responder = cell.nextResponder;
            NSArray<__kindof UIView *> *subviews = [tableView.superview subviews];
            NSMutableArray<__kindof UIView *> *viewsArray = [[NSMutableArray alloc] init];
            for (UIView *obj in subviews) {
                if ([NSStringFromClass([responder class]) isEqualToString:NSStringFromClass([obj class])]) {
                    [viewsArray addObject:obj];
                }
            }
            if ([viewsArray count] == 1) {
                [viewPathArray addObject:NSStringFromClass([responder class])];
            } else {
                NSUInteger index = [viewsArray indexOfObject:tableView];
                [viewPathArray addObject:[NSString stringWithFormat:@"%@[%lu]", NSStringFromClass([responder class]), (unsigned long)index]];
            }
            responder = [responder nextResponder];
            [self sa_find_responder:responder withViewPathArray:viewPathArray];

            NSArray *array = [[viewPathArray reverseObjectEnumerator] allObjects];

            NSMutableString *viewPath = [[NSMutableString alloc] init];
            for (int i = 0; i < array.count; i++) {
                [viewPath appendString:array[i]];
                if (i != (array.count - 1)) {
                    [viewPath appendString:@"/"];
                }
            }
            NSRange range = [viewPath rangeOfString:@"UITableViewWrapperView/"];
            if (range.length) {
                [viewPath deleteCharactersInRange:range];
            }
            [properties setValue:viewPath forKey:SA_EVENT_PROPERTY_ELEMENT_SELECTOR];
        }

        elementContent = [self contentFromView:cell];
        if (elementContent.length > 0) {
            [properties setValue:elementContent forKey:SA_EVENT_PROPERTY_ELEMENT_CONTENT];
        }

        //View Properties
        NSDictionary* propDict = view.sensorsAnalyticsViewProperties;
        if (propDict != nil) {
            [properties addEntriesFromDictionary:propDict];
        }

        @try {
            if (view.sensorsAnalyticsDelegate) {
                if ([view.sensorsAnalyticsDelegate conformsToProtocol:@protocol(SAUIViewAutoTrackDelegate)] && [view.sensorsAnalyticsDelegate respondsToSelector:@selector(sensorsAnalytics_tableView:autoTrackPropertiesAtIndexPath:)]) {
                        [properties addEntriesFromDictionary:[view.sensorsAnalyticsDelegate sensorsAnalytics_tableView:tableView autoTrackPropertiesAtIndexPath:indexPath]];
                }
            }
        } @catch (NSException *exception) {
            SAError(@"%@ error: %@", self, exception);
        }

        [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

+ (void)sa_addViewPathProperties:(NSMutableDictionary *)properties withObject:(UIView *)view withViewController:(UIViewController *)viewController {
    @try {
        if (![[SensorsAnalyticsSDK sharedInstance] isHeatMapEnabled]) {
            return;
        }

        if (![[SensorsAnalyticsSDK sharedInstance] isHeatMapViewController:viewController]) {
            return;
        }

        NSMutableArray *viewPathArray = [[NSMutableArray alloc] init];

        [self sa_find_view_responder:view withViewPathArray:viewPathArray];
        
        id responder = view.nextResponder;
        [self sa_find_responder:responder withViewPathArray:viewPathArray];
        
        NSArray *array = [[viewPathArray reverseObjectEnumerator] allObjects];
        
        NSString *viewPath = [[NSString alloc] init];
        for (int i = 0; i < array.count; i++) {
            viewPath = [viewPath stringByAppendingString:array[i]];
            if (i != (array.count - 1)) {
                viewPath = [viewPath stringByAppendingString:@"/"];
            }
        }
        [properties setValue:viewPath forKey:SA_EVENT_PROPERTY_ELEMENT_SELECTOR];
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

@end

