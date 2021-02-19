//
// SAViewElementType.m
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

#import "SAViewElementType.h"

#pragma mark - View Element Type
@implementation SAViewElementType

- (NSString *)elementTypeWithView:(UIView *)view {
    return NSStringFromClass(view.class);
}

@end

#pragma mark - Alert Element Type
@implementation SAAlertElementType

- (NSString *)elementTypeWithView:(UIView *)view {
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    UIWindow *window = view.window;
    if ([NSStringFromClass(window.class) isEqualToString:@"_UIAlertControllerShimPresenterWindow"]) {
        CGFloat actionHeight = view.bounds.size.height;
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

@end

#pragma mark - Menu Element Type
@implementation SAMenuElementType

- (NSString *)elementTypeWithView:(UIView *)view {
    if (@available(iOS 13.0, *)) {
        return NSStringFromClass(UIMenu.class);
    }
    return @"UIMenu";
}

@end
