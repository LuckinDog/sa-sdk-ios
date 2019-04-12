//
//  AutoTrackUtils.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/6/29.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
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
    } else {
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
            [properties setValue:[NSString stringWithFormat: @"%ld:%ld", (unsigned long)indexPath.section, (unsigned long)indexPath.row] forKey:SA_EVENT_PROPERTY_ELEMENT_POSITION];
        }

        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        if (!cell) {
            [collectionView layoutIfNeeded];
            cell = [collectionView cellForItemAtIndexPath:indexPath];
        }

        [self sa_addIndexPathProperties:properties object:collectionView cell:cell indexPath:indexPath viewController:viewController];
        
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
            if ([view.sensorsAnalyticsDelegate conformsToProtocol:@protocol(SAUIViewAutoTrackDelegate)] && [view.sensorsAnalyticsDelegate respondsToSelector:@selector(sensorsAnalytics_collectionView:autoTrackPropertiesAtIndexPath:)]) {
                    [properties addEntriesFromDictionary:[view.sensorsAnalyticsDelegate sensorsAnalytics_collectionView:collectionView autoTrackPropertiesAtIndexPath:indexPath]];
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
            [properties setValue:[NSString stringWithFormat: @"%ld:%ld", (unsigned long)indexPath.section, (unsigned long)indexPath.row] forKey:SA_EVENT_PROPERTY_ELEMENT_POSITION];
        }

        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (!cell) {
            [tableView layoutIfNeeded];
            cell = [tableView cellForRowAtIndexPath:indexPath];
        }

        [self sa_addIndexPathProperties:properties object:tableView cell:cell indexPath:indexPath viewController:viewController];

        NSString *elementContent = [[NSString alloc] init];
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
            if ([view.sensorsAnalyticsDelegate conformsToProtocol:@protocol(SAUIViewAutoTrackDelegate)] && [view.sensorsAnalyticsDelegate respondsToSelector:@selector(sensorsAnalytics_tableView:autoTrackPropertiesAtIndexPath:)]) {
                    [properties addEntriesFromDictionary:[view.sensorsAnalyticsDelegate sensorsAnalytics_tableView:tableView autoTrackPropertiesAtIndexPath:indexPath]];
            }
        } @catch (NSException *exception) {
            SAError(@"%@ error: %@", self, exception);
        }

        [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

+ (void)sa_addViewPathProperties:(NSMutableDictionary *)properties object:(UIView *)view viewController:(UIViewController *)viewController {
    @try {
        SensorsAnalyticsSDK *sa = [SensorsAnalyticsSDK sharedInstance];
        BOOL isEnabled = [sa isVirtualAutoTrackEventEnabled] || [sa isHeatMapEnabled];
        BOOL isContains = [sa isVirtualAutoTrackEventViewController:viewController] || [sa isHeatMapViewController:viewController];
        if (!isEnabled || !isContains) {
            return;
        }

        NSMutableArray *viewPathArray = [[NSMutableArray alloc] init];
        id  responder= [self sa_find_view_responder:view withViewPathArray:viewPathArray];
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

+ (void)sa_addIndexPathProperties:(NSMutableDictionary *)properties object:(UIScrollView *)scrollView cell:(UIView *)cell indexPath:(NSIndexPath *)indexPath viewController:(UIViewController *)viewController {
    SensorsAnalyticsSDK *sa = [SensorsAnalyticsSDK sharedInstance];
    BOOL isEnabled = [sa isVirtualAutoTrackEventEnabled] || [sa isHeatMapEnabled];
    BOOL isContains = [sa isVirtualAutoTrackEventViewController:viewController] || [sa isHeatMapViewController:viewController];
    if (isEnabled && isContains) {
        NSMutableArray *viewPathArray = [[NSMutableArray alloc] init];
        [viewPathArray addObject:[NSString stringWithFormat:@"%@[%ld][%ld]", NSStringFromClass([cell class]), (long)indexPath.section, (long)indexPath.row]];
        
        id responder = [self sa_find_view_responder:scrollView withViewPathArray:viewPathArray];
        [self sa_find_responder:responder withViewPathArray:viewPathArray];
        
        NSArray *array = [[viewPathArray reverseObjectEnumerator] allObjects];
        
        NSMutableString *viewPath = [[NSMutableString alloc] init];
        for (int i = 0; i < array.count; i++) {
            [viewPath appendString:array[i]];
            if (i != (array.count - 1)) {
                [viewPath appendString:@"/"];
            }
        }
        
        if ([scrollView isKindOfClass:UITableView.class]) {
            NSRange range = [viewPath rangeOfString:@"UITableViewWrapperView/"];
            if (range.length) {
                [viewPath deleteCharactersInRange:range];
            }
        }
        [properties setValue:viewPath forKey:SA_EVENT_PROPERTY_ELEMENT_SELECTOR];
    }
}

+ (id)sa_find_view_responder:(UIView *)view withViewPathArray:(NSMutableArray *)viewPathArray {
    do {
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

            //UITableViewHeaderFooterView 点击的 index 问题
            if ([view isKindOfClass:UITableViewHeaderFooterView.class]) {
                NSString *headerFooterSection = [view performSelector:@selector(sa_section)];
                if (headerFooterSection.length) {
                    [viewPathArray removeLastObject];
                    [viewPathArray addObject:[NSString stringWithFormat:@"%@%@", NSStringFromClass(view.class), headerFooterSection]];
                }
            }
            //UISegmentedControl 点击的 index 问题
            if ([view isKindOfClass:UISegmentedControl.class]) {
                NSInteger selectedSegmentIndex = [(UISegmentedControl *)view selectedSegmentIndex];
                NSString *selectedSegmentPath = [NSString stringWithFormat:@"%@[%ld]", @"UISegment", (long)selectedSegmentIndex];
                [viewPathArray insertObject:selectedSegmentPath atIndex:0];
            }
            //UITabBar 点击的 index 问题
            if ([view isKindOfClass:UITabBar.class]) {
                UITabBar *tabBar = (UITabBar *)view;
                NSInteger selectedIndex = [[tabBar items] indexOfObject:tabBar.selectedItem];
                NSString *selectedSegmentPath = [NSString stringWithFormat:@"%@[%ld]", @"UITabBarButton", (long)selectedIndex];
                [viewPathArray insertObject:selectedSegmentPath atIndex:0];
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

            //UITableViewHeaderFooterView 点击的 index 问题
            if ([view isKindOfClass:UITableViewHeaderFooterView.class]) {
                NSString *headerFooterSection = [view performSelector:@selector(sa_section)];
                if (headerFooterSection.length) {
                    [viewPathArray removeLastObject];
                    [viewPathArray addObject:[NSString stringWithFormat:@"%@%@", NSStringFromClass(view.class), headerFooterSection]];
                }
            }
            //UISegmentedControl 点击的 index 问题
            if ([view isKindOfClass:UISegmentedControl.class]) {
                NSInteger selectedSegmentIndex = [(UISegmentedControl *)view selectedSegmentIndex];
                NSString *selectedSegmentPath = [NSString stringWithFormat:@"%@[%ld]", @"UISegment", (long)selectedSegmentIndex];
                [viewPathArray insertObject:selectedSegmentPath atIndex:0];
            }
            //UITabBar 点击的 index 问题
            if ([view isKindOfClass:UITabBar.class]) {
                UITabBar *tabBar = (UITabBar *)view;
                NSInteger selectedIndex = [[tabBar items] indexOfObject:tabBar.selectedItem];
                NSString *selectedSegmentPath = [NSString stringWithFormat:@"%@[%ld]", @"UITabBarButton", (long)selectedIndex];
                [viewPathArray insertObject:selectedSegmentPath atIndex:0];
            }
        }
    }while ((view = (id)view.nextResponder) &&[view isKindOfClass:UIView.class] && ![view isKindOfClass:UIWindow.class]);
    return view;
}

+ (void)sa_find_responder:(id)responder withViewPathArray:(NSMutableArray *)viewPathArray {
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
        if ([(UIViewController *)responder presentingViewController]) {
            [self sa_find_responder:[responder presentingViewController] withViewPathArray:viewPathArray];
        }
    }
}

+ (void)trackAppClickWithUITabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item{
    //插入埋点
    @try {
        //关闭 AutoTrack
        if (![[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled]) {
            return;
        }

        //忽略 $AppClick 事件
        if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
            return;
        }

        if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UITabBar class]]) {
            return;
        }

        if (!tabBar) {
            return;
        }

        UIView *view = (UIView *)tabBar;
        if (!view) {
            return;
        }

        if (view.sensorsAnalyticsIgnoreView) {
            return;
        }
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        [properties setValue:@"UITabBar" forKey:@"$element_type"];
        //ViewID
        if (view.sensorsAnalyticsViewID != nil) {
            [properties setValue:view.sensorsAnalyticsViewID forKey:@"$element_id"];
        }
        UIViewController *viewController = [view sensorsAnalyticsViewController];

        if (viewController == nil ||
            [@"UINavigationController" isEqualToString:NSStringFromClass([viewController class])]) {
            viewController = [[SensorsAnalyticsSDK sharedInstance] currentViewController];
        }

        if (viewController != nil) {
            if ([[SensorsAnalyticsSDK sharedInstance] isViewControllerIgnored:viewController]) {
                return;
            }

            //获取 Controller 名称($screen_name)
            NSString *screenName = NSStringFromClass([viewController class]);
            [properties setValue:screenName forKey:@"$screen_name"];

            NSString *controllerTitle = [AutoTrackUtils titleFromViewController:viewController];
            if (controllerTitle != nil) {
                [properties setValue:controllerTitle forKey:@"$title"];
            }
        }

        if (item) {
            [properties setValue:item.title forKey:@"$element_content"];
        }

        //View Properties
        NSDictionary* propDict = view.sensorsAnalyticsViewProperties;
        if (propDict != nil) {
            [properties addEntriesFromDictionary:propDict];
        }

        [AutoTrackUtils sa_addViewPathProperties:properties object:view viewController:viewController];
        [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" withProperties:properties];
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

+ (void)trackAppClickWithUIGestureRecognizer:(UIGestureRecognizer *)gesture{
    @try {
        if (gesture == nil) {
            return;
        }

        if (gesture.state != UIGestureRecognizerStateEnded) {
            return;
        }

        UIView *view = gesture.view;
        if (view == nil) {
            return;
        }
        //关闭 AutoTrack
        if (![SensorsAnalyticsSDK.sharedInstance isAutoTrackEnabled]) {
            return;
        }

        //忽略 $AppClick 事件
        if ([SensorsAnalyticsSDK.sharedInstance isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
            return;
        }

        if ([view isKindOfClass:[UILabel class]]) {//UILabel
            if ([SensorsAnalyticsSDK.sharedInstance isViewTypeIgnored:[UILabel class]]) {
                return;
            }
        } else if ([view isKindOfClass:[UIImageView class]]) {//UIImageView
            if ([SensorsAnalyticsSDK.sharedInstance isViewTypeIgnored:[UIImageView class]]) {
                return;
            }
        }

        if (view.sensorsAnalyticsIgnoreView) {
            return;
        }

        UIViewController *viewController = [SensorsAnalyticsSDK.sharedInstance currentViewController];
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];

        if (viewController != nil) {
            if ([[SensorsAnalyticsSDK sharedInstance] isViewControllerIgnored:viewController]) {
                return;
            }

            //获取 Controller 名称($screen_name)
            NSString *screenName = NSStringFromClass([viewController class]);
            [properties setValue:screenName forKey:@"$screen_name"];

            NSString *controllerTitle = [AutoTrackUtils titleFromViewController:viewController];
            if (controllerTitle != nil) {
                [properties setValue:viewController.navigationItem.title forKey:@"$title"];
            }
        }

        //ViewID
        if (view.sensorsAnalyticsViewID != nil) {
            [properties setValue:view.sensorsAnalyticsViewID forKey:@"$element_id"];
        }

        if ([view isKindOfClass:[UILabel class]]) {
            [properties setValue:@"UILabel" forKey:@"$element_type"];
            UILabel *label = (UILabel *)view;
            NSString *sa_elementContent = label.sa_elementContent;
            if (sa_elementContent && sa_elementContent.length > 0) {
                [properties setValue:sa_elementContent forKey:@"$element_content"];
            }
        } else if ([view isKindOfClass:[UIImageView class]]) {
            [properties setValue:@"UIImageView" forKey:@"$element_type"];
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UIIMAGE_IMAGENAME
            UIImageView *imageView = (UIImageView *)view;
            if (imageView) {
                if (imageView.image) {
                    NSString *imageName = imageView.image.sensorsAnalyticsImageName;
                    if (imageName != nil) {
                        [properties setValue:[NSString stringWithFormat:@"$%@", imageName] forKey:@"$element_content"];
                    }
                }
            }
#endif
        } else {
            return;
        }

        //View Properties
        NSDictionary* propDict = view.sensorsAnalyticsViewProperties;
        if (propDict != nil) {
            [properties addEntriesFromDictionary:propDict];
        }

        [AutoTrackUtils sa_addViewPathProperties:properties object:view viewController:viewController];
        [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" withProperties:properties];
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}
@end

