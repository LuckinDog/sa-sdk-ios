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
#import "SAAutoTrack.h"
#import "SAConstants.h"
#import "SensorsAnalyticsSDK.h"
#import "AutoTrackUtils.h"

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

#pragma mark - Property
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

    viewController = viewController ?: object.sensorsdata_superViewController;
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
    NSDictionary* propDict = view.sensorsAnalyticsViewProperties;
    if (propDict != nil) {
        [properties addEntriesFromDictionary:propDict];
    }

    [AutoTrackUtils sa_addViewPathProperties:properties object:view viewController:viewController];

    return [properties copy];
}

@end
