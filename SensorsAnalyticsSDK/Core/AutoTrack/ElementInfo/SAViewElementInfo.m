//
// SAViewElementInfo.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/18.
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

#import "SAViewElementInfo.h"

#pragma mark - View Element Type
@implementation SAViewElementInfo

- (instancetype)initWithView:(UIView *)view {
    if (self = [super init]) {
        self.view = view;
    }
    return self;
}

- (NSString *)elementType {
    return NSStringFromClass(self.view.class);
}

- (NSString *)elementPosition {
    if ([self.view conformsToProtocol:@protocol(SAAutoTrackCellProperty)]) {
        id<SAAutoTrackCellProperty> cell = (id<SAAutoTrackCellProperty>)self.view;
        if (cell.sensorsdata_IndexPath) {
            return [[NSString alloc] initWithFormat:@"%ld:%ld", (long)cell.sensorsdata_IndexPath.section, (long)cell.sensorsdata_IndexPath.item];
        }
    }
    return nil;
}

- (NSString *)elementSimilarPathWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%@[%ld][-]", NSStringFromClass(self.view.class), (long)indexPath.section];
}

@end

#pragma mark - Alert Element Type
@implementation SAAlertElementInfo

- (instancetype)initWithView:(UIView *)view {
    if (self = [super init]) {
        self.view = view;
    }
    return self;
}

- (NSString *)elementType {
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    UIWindow *window = self.view.window;
    if ([NSStringFromClass(window.class) isEqualToString:@"_UIAlertControllerShimPresenterWindow"]) {
        CGFloat actionHeight = self.view.bounds.size.height;
        if (actionHeight > 50) {
            return NSStringFromClass(UIActionSheet.class);
        } else {
            return NSStringFromClass(UIAlertView.class);
        }
    } else {
        return NSStringFromClass(UIAlertController.class);
    }
#else
    return NSStringFromClass(UIAlertController.class);
#endif
}

- (NSString *)elementPosition {
    return nil;
}

- (NSString *)elementSimilarPathWithIndexPath:(NSIndexPath *)indexPath {
    if ([self.view conformsToProtocol:@protocol(SAAutoTrackCellProperty)]) {
        id<SAAutoTrackCellProperty> cell = (id<SAAutoTrackCellProperty>)self.view;
        return [cell sensorsdata_itemPathWithIndexPath:indexPath];
    }
    return nil;
}

@end

#pragma mark - Menu Element Type
@implementation SAMenuElementInfo

- (instancetype)initWithView:(UIView *)view {
    if (self = [super init]) {
        self.view = view;
    }
    return self;
}

- (NSString *)elementType {
    if (@available(iOS 13.0, *)) {
        return NSStringFromClass(UIMenu.class);
    }
    return @"UIMenu";
}

- (NSString *)elementPosition {
    return nil;
}

- (NSString *)elementSimilarPathWithIndexPath:(NSIndexPath *)indexPath {
    if ([self.view conformsToProtocol:@protocol(SAAutoTrackCellProperty)]) {
        id<SAAutoTrackCellProperty> cell = (id<SAAutoTrackCellProperty>)self.view;
        return [cell sensorsdata_itemPathWithIndexPath:indexPath];
    }
    return nil;
}

@end
