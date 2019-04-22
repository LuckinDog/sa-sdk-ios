//
//  UIView+sa_autoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/6/11.
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

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+AutoTrack.h"
#import "SAAutoTrackUtils.h"
#import "SensorsAnalyticsSDK.h"

#pragma mark - UIView

@implementation UIView (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    BOOL isAutoTrackEnabled = [[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled];
    BOOL isAutoTrackEventTypeIgnored = [[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick];
    BOOL isViewTypeIgnored = [[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[self class]];
    return !isAutoTrackEnabled || isAutoTrackEventTypeIgnored || isViewTypeIgnored || self.sensorsAnalyticsIgnoreView;
}

- (NSString *)sensorsdata_elementType {
    return NSStringFromClass(self.class);
}

- (NSString *)sensorsdata_elementContent {
    if (self.isHidden || self.sensorsAnalyticsIgnoreView) {
        return nil;
    }

    NSMutableString *elementContent = [NSMutableString string];

    if ([self isKindOfClass:NSClassFromString(@"RTLabel")]) {   // RTLabel:https://github.com/honcheng/RTLabel
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([self respondsToSelector:NSSelectorFromString(@"text")]) {
            NSString *title = [self performSelector:NSSelectorFromString(@"text")];
            if (title.length > 0) {
                [elementContent appendString:title];
            }
        }
#pragma clang diagnostic pop
    } else if ([self isKindOfClass:NSClassFromString(@"YYLabel")]) {    // RTLabel:https://github.com/ibireme/YYKit
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([self respondsToSelector:NSSelectorFromString(@"text")]) {
            NSString *title = [self performSelector:NSSelectorFromString(@"text")];
            if (title.length > 0) {
                [elementContent appendString:title];
            }
        }
#pragma clang diagnostic pop
    } else {
        NSMutableArray<NSString *> *elementContentArray = [NSMutableArray array];
        for (UIView *subview in self.subviews) {
            NSString *temp = subview.sensorsdata_elementContent;
            if (temp.length > 0) {
                [elementContentArray addObject:temp];
            }
        }
        if (elementContentArray.count > 0) {
            [elementContent appendString:[elementContentArray componentsJoinedByString:@"-"]];
        }
    }

    return elementContent.length == 0 ? nil : [elementContent copy];
}

- (NSString *)sensorsdata_elementPosition {
    return nil;
}

- (NSString *)sensorsdata_elementId {
    return self.sensorsAnalyticsViewID;
}

- (UIViewController *)sensorsdata_superViewController {
    UIViewController *viewController = [SAAutoTrackUtils findNextViewControllerByResponder:self];
    if ([viewController isKindOfClass:UINavigationController.class]) {
        viewController = [SAAutoTrackUtils currentViewController];
    }
    return viewController;
}

@end

@implementation UILabel (AutoTrack)

- (NSString *)sensorsdata_elementContent {
    return self.text;
}

@end

@implementation UITextView (AutoTrack)

- (NSString *)sensorsdata_elementContent {
    return self.text;
}

@end

@implementation UITabBar (AutoTrack)

- (NSString *)sensorsdata_elementType {
    return @"UITabBar";
}

- (NSString *)sensorsdata_elementContent {
    return self.selectedItem.title;
}

@end

@implementation UISearchBar (AutoTrack)

- (NSString *)sensorsdata_elementType {
    return @"UISearchBar";
}

- (NSString *)sensorsdata_elementContent {
    return self.text;
}

@end

#pragma mark - UIControl

@implementation UIControl (AutoTrack)

- (NSString *)sensorsdata_elementType {
    return @"UIControl";
}

@end

@implementation UIButton (AutoTrack)

- (NSString *)sensorsdata_elementType {
    return @"UIButton";
}

- (NSString *)sensorsdata_elementContent {
    NSString *text = super.sensorsdata_elementContent;
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UIIMAGE_IMAGENAME
    if (text.length == 0) {
        NSString *imageName = self.currentImage.sensorsAnalyticsImageName;
        if (imageName.length > 0) {
            return [NSString stringWithFormat:@"$%@", imageName];
        }
    }
#endif
    return text;
}

@end

@implementation UISwitch (AutoTrack)

- (NSString *)sensorsdata_elementType {
    return @"UISwitch";
}

- (NSString *)sensorsdata_elementContent {
    return self.on ? @"checked" : @"unchecked";
}

@end

@implementation UIStepper (AutoTrack)

- (NSString *)sensorsdata_elementType {
    return @"UIStepper";
}

- (NSString *)sensorsdata_elementContent {
    return [NSString stringWithFormat:@"%g", self.value];
}

@end

@implementation UISegmentedControl (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    return super.sensorsdata_isIgnored && self.selectedSegmentIndex == UISegmentedControlNoSegment;
}

- (NSString *)sensorsdata_elementType {
    return @"UISegmentedControl";
}

- (NSString *)sensorsdata_elementContent {
    return [self titleForSegmentAtIndex:self.selectedSegmentIndex];
}

- (NSString *)sensorsdata_elementPosition {
    return [NSString stringWithFormat: @"%ld", (long)self.selectedSegmentIndex];
}

@end

@implementation UISlider (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    NSLog(@"%d, %d", self.tracking, self.touchInside);
    return (!self.tracking && self.touchInside) || super.sensorsdata_isIgnored;
}

- (NSString *)sensorsdata_elementType {
    return @"UISlider";
}

- (NSString *)sensorsdata_elementContent {
    return [NSString stringWithFormat:@"%f", self.value];
}

@end

#pragma mark - UIBarItem

@implementation UIBarItem (AutoTrack)

- (BOOL)sensorsdata_isIgnored {
    BOOL isAutoTrackEnabled = [[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled];
    BOOL isAutoTrackEventTypeIgnored = [[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick];
    BOOL isViewTypeIgnored = [[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[self class]];
    return !isAutoTrackEnabled || isAutoTrackEventTypeIgnored || isViewTypeIgnored;
}

- (NSString *)sensorsdata_elementId {
    return nil;
}

- (NSString *)sensorsdata_elementType {
    return nil;
}

- (NSString *)sensorsdata_elementContent {
    return self.title;
}

- (NSString *)sensorsdata_elementPosition {
    return nil;
}

- (UIViewController *)sensorsdata_superViewController {
    return nil;
}

@end

@implementation UIBarButtonItem (AutoTrack)

- (NSString *)sensorsdata_elementType {
    return @"UIBarButtonItem";
}

@end

@implementation UITabBarItem (AutoTrack)

- (NSString *)sensorsdata_elementType {
    return @"UITabbar";
}

@end
