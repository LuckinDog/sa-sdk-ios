//
//  SAAutoTrackUtils.m
//  SensorsAnalyticsSDK
//
//  Created by MC on 2019/4/22.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
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

#import "SAAutoTrackUtils.h"
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK.h"
#import "UIView+SAHelpers.h"

@implementation SAAutoTrackUtils

+ (UIViewController *)findNextViewControllerByResponder:(UIResponder *)responder {
    UIResponder *next = [responder nextResponder];
    do {
        if ([next isKindOfClass:UIViewController.class]) {
            UIViewController *vc = (UIViewController *)next;
            if ([vc isKindOfClass:UINavigationController.class]) {
                next = [(UINavigationController *)vc topViewController];
                break;
            } else if ([vc isKindOfClass:UITabBarController.class]) {
                next = [(UITabBarController *)vc selectedViewController];
                break;
            }
            UIViewController *parentVC = vc.parentViewController;
            if (parentVC) {
                if ([parentVC isKindOfClass:UINavigationController.class] ||
                    [parentVC isKindOfClass:UITabBarController.class] ||
                    [parentVC isKindOfClass:UIPageViewController.class] ||
                    [parentVC isKindOfClass:UISplitViewController.class]) {
                    break;
                }
            } else {
                break;
            }
        }
    } while ((next = next.nextResponder));
    return [next isKindOfClass:UIViewController.class] ? (UIViewController *)next : nil;
}

+ (UIViewController *)findSuperViewControllerByView:(UIView *)view {
    UIViewController *viewController = [SAAutoTrackUtils findNextViewControllerByResponder:view];
    if ([viewController isKindOfClass:UINavigationController.class]) {
        viewController = [SAAutoTrackUtils currentViewController];
    }
    return viewController;
}

+ (UIViewController *)currentViewController {
    __block UIViewController *currentViewController = nil;
    void (^ block)(void) = ^{
        UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
        currentViewController = [SAAutoTrackUtils findCurrentViewControllerFromRootViewController:rootViewController isRoot:YES];
    };

    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }

    return currentViewController;
}

+ (UIViewController *)findCurrentViewControllerFromRootViewController:(UIViewController *)viewController isRoot:(BOOL)isRoot {
    UIViewController *currentViewController = nil;
    if (viewController.presentedViewController) {
        viewController = [self findCurrentViewControllerFromRootViewController:viewController.presentedViewController isRoot:NO];
    }

    if ([viewController isKindOfClass:[UITabBarController class]]) {
        currentViewController = [self findCurrentViewControllerFromRootViewController:[(UITabBarController *)viewController selectedViewController] isRoot:NO];
    } else if ([viewController isKindOfClass:[UINavigationController class]]) {
        // 根视图为UINavigationController
        currentViewController = [self findCurrentViewControllerFromRootViewController:[(UINavigationController *)viewController visibleViewController] isRoot:NO];
    } else if ([viewController respondsToSelector:NSSelectorFromString(@"contentViewController")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        UIViewController *tempViewController = [viewController performSelector:NSSelectorFromString(@"contentViewController")];
#pragma clang diagnostic pop
        if (tempViewController) {
            currentViewController = [self findCurrentViewControllerFromRootViewController:tempViewController isRoot:NO];
        }
    } else if (viewController.childViewControllers.count == 1 && isRoot) {
        currentViewController = [self findCurrentViewControllerFromRootViewController:viewController.childViewControllers.firstObject isRoot:NO];
    } else {
        currentViewController = viewController;
    }
    return currentViewController;
}

@end

#pragma mark -
@implementation SAAutoTrackUtils (Property)

+ (NSDictionary<NSString *, NSString *> *)propertiesWithViewController:(UIViewController<SAAutoTrackViewController> *)viewController {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[SA_EVENT_PROPERTY_SCREEN_NAME] = viewController.sensorsdata_screenName;
    properties[SA_EVENT_PROPERTY_TITLE] = viewController.sensorsdata_title;
    return [properties copy];
}

+ (NSDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackView>)object {
    return [self propertiesWithAutoTrackObject:object viewController:nil isIgnoredViewPath:NO];
}

+ (NSDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackView>)object isIgnoredViewPath:(BOOL)isIgnoredViewPath {
    return [self propertiesWithAutoTrackObject:object viewController:nil isIgnoredViewPath:isIgnoredViewPath];
}

+ (NSDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackView>)object viewController:(nullable UIViewController<SAAutoTrackViewController> *)viewController {
    return [self propertiesWithAutoTrackObject:object viewController:viewController isIgnoredViewPath:NO];
}

+ (NSDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackView>)object viewController:(nullable UIViewController<SAAutoTrackViewController> *)viewController isIgnoredViewPath:(BOOL)isIgnoredViewPath {
    if (object.sensorsdata_isIgnored) {
        return nil;
    }
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    // ViewID
    properties[SA_EVENT_PROPERTY_ELEMENT_ID] = object.sensorsdata_elementId;

    viewController = viewController ? : object.sensorsdata_superViewController;
    if (viewController.sensorsdata_isIgnored) {
        return nil;
    }
    NSDictionary *dic = [self propertiesWithViewController:viewController];
    [properties addEntriesFromDictionary:dic];

    properties[SA_EVENT_PROPERTY_ELEMENT_TYPE] = object.sensorsdata_elementType;
    properties[SA_EVENT_PROPERTY_ELEMENT_CONTENT] = object.sensorsdata_elementContent;
    properties[SA_EVENT_PROPERTY_ELEMENT_POSITION] = object.sensorsdata_elementPosition;

    if (isIgnoredViewPath || ![object isKindOfClass:UIView.class]) {
        return [properties copy];
    }
    UIView *view = (UIView *)object;
    //View Properties
    NSDictionary *propDict = view.sensorsAnalyticsViewProperties;
    if (propDict != nil) {
        [properties addEntriesFromDictionary:propDict];
    }

    NSString *viewPath = [self viewPathForView:view atViewController:viewController];
    if (viewPath) {
        properties[SA_EVENT_PROPERTY_ELEMENT_SELECTOR] = viewPath;
    }

    return [properties copy];
}

@end

#pragma mark -
@implementation SAAutoTrackUtils (ViewPath)

+ (BOOL)isIgnoredViewPathForViewController:(UIViewController *)viewController {
    SensorsAnalyticsSDK *sa = [SensorsAnalyticsSDK sharedInstance];

    BOOL isEnableVisualizedAutoTrack = [sa isVisualizedAutoTrackEnabled] && [sa isVisualizedAutoTrackViewController:viewController];
    BOOL isEnableHeatMap = [sa isHeatMapEnabled] && [sa isHeatMapViewController:viewController];
    return !isEnableVisualizedAutoTrack && !isEnableHeatMap;
}

+ (NSArray<NSString *> *)viewPathsForViewController:(UIViewController<SAAutoTrackViewPath> *)viewController {
    NSMutableArray *viewPaths = [NSMutableArray array];
    do {
        [viewPaths addObject:viewController.sensorsdata_itemPath];
        viewController = (UIViewController<SAAutoTrackViewPath> *)viewController.parentViewController;
    } while (viewController);

    UIViewController<SAAutoTrackViewPath> *vc = (UIViewController<SAAutoTrackViewPath> *)viewController.presentingViewController;
    if ([vc conformsToProtocol:@protocol(SAAutoTrackViewPath)]) {
        [viewPaths addObjectsFromArray:[self viewPathsForViewController:vc]];
    }
    return viewPaths;
}

+ (NSArray<NSString *> *)viewPathsForView:(UIView<SAAutoTrackViewPath> *)view {
    NSMutableArray *viewPathArray = [NSMutableArray array];
    do {
        [viewPathArray addObject:view.sensorsdata_itemPath];
    } while ((view = (id)view.nextResponder) && [view isKindOfClass:UIView.class] && ![view isKindOfClass:UIWindow.class]);

    if ([view isKindOfClass:UIViewController.class] && [view conformsToProtocol:@protocol(SAAutoTrackViewPath)]) {
        [viewPathArray addObjectsFromArray:[self viewPathsForViewController:(UIViewController<SAAutoTrackViewPath> *)view]];
    }
    return viewPathArray;
}

+ (NSString *)viewPathForView:(UIView *)view atViewController:(UIViewController *)viewController {
    if ([self isIgnoredViewPathForViewController:viewController]) {
        return nil;
    }
    NSArray *viewPaths = [[[self viewPathsForView:view] reverseObjectEnumerator] allObjects];
    NSString *viewPath = [viewPaths componentsJoinedByString:@"/"];

    NSRange range = [viewPath rangeOfString:@"UITableViewWrapperView/"];
    if (range.location != NSNotFound) {
        viewPath = [viewPath stringByReplacingCharactersInRange:range withString:@""];
    }

    return viewPath;
}

+ (NSString *)itemPathForResponder:(UIResponder *)responder {
    NSString *classString = NSStringFromClass(responder.class);

    NSArray *subResponder = nil;
    if ([responder isKindOfClass:UIView.class]) {
        UIResponder *next = [responder nextResponder];
        if ([next isKindOfClass:UIView.class]) {
            subResponder = [(UIView *)next subviews];
        }
    } else if ([responder isKindOfClass:UIViewController.class]) {
        subResponder = [(UIViewController *)responder parentViewController].childViewControllers;
    }

    NSInteger count = 0;
    NSInteger index = -1;
    for (UIResponder *res in subResponder) {
        if ([classString isEqualToString:NSStringFromClass(res.class)]) {
            count++;
        }
        if (res == responder) {
            index = count - 1;
        }
    }
    return count == 1 ? classString : [NSString stringWithFormat:@"%@[%lu]", classString, index];
}

+ (NSString *)viewIdentifierForView:(UIView *)view {
    NSMutableArray *valueArray = [[NSMutableArray alloc] init];
    NSString *value = [view jjf_varE];
    if (value) {
        [valueArray addObject:[NSString stringWithFormat:@"jjf_varE='%@'", value]];
    }
    value = [view jjf_varC];
    if (value) {
        [valueArray addObject:[NSString stringWithFormat:@"jjf_varC='%@'", value]];
    }
    value = [view jjf_varB];
    if (value) {
        [valueArray addObject:[NSString stringWithFormat:@"jjf_varB='%@'", value]];
    }
    value = [view jjf_varA];
    if (value) {
        [valueArray addObject:[NSString stringWithFormat:@"jjf_varA='%@'", value]];
    }
    if (valueArray.count == 0) {
        return nil;
    }
    NSString *viewVarString = [valueArray componentsJoinedByString:@" AND "];
    return [NSString stringWithFormat:@"%@[(%@)]", NSStringFromClass([view class]), viewVarString];
}

@end


#pragma mark -
@implementation SAAutoTrackUtils (IndexPath)
@end
