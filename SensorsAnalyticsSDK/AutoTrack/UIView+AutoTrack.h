//
//  UIView+sa_autoTrack.h
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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#pragma mark - 
@protocol SAUIViewAutoTrack
@property (nonatomic, readonly) BOOL sensorsdata_isIgnored;

@property (nonatomic, copy, readonly) NSString *sensorsdata_elementType;
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementContent;
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementId;
/// 只在 UISegmentedControl 中返回选中的 index，其他类型返回 nil
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementPosition;

/// 获取 view 所在的 viewController，或者当前的 viewController
@property (nonatomic, readonly) UIViewController *sensorsdata_superViewController;
@end

#pragma mark - UIView

@interface UIView (AutoTrack) <SAUIViewAutoTrack>
@end

@interface UILabel (AutoTrack) <SAUIViewAutoTrack>
@end

@interface UITextView (AutoTrack) <SAUIViewAutoTrack>
@end

@interface UITabBar (AutoTrack) <SAUIViewAutoTrack>
@end

@interface UISearchBar (AutoTrack) <SAUIViewAutoTrack>
@end

#pragma mark - UIControl

@interface UIButton (AutoTrack) <SAUIViewAutoTrack>
@end

@interface UISwitch (AutoTrack) <SAUIViewAutoTrack>
@end

@interface UIStepper (AutoTrack) <SAUIViewAutoTrack>
@end

@interface UISegmentedControl (AutoTrack) <SAUIViewAutoTrack>
@end

#pragma mark - UIBarItem

@interface UIBarItem (AutoTrack) <SAUIViewAutoTrack>
@end

@interface UIBarButtonItem (AutoTrack) <SAUIViewAutoTrack>
@end

@interface UITabBarItem (AutoTrack) <SAUIViewAutoTrack>
@end

