//
// UIView+ElementPath.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/3/6.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "SAAutoTrackProperty.h"
#import "SAJSTouchEventView.h"
#import "SAVisualizedViewPathProperty.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIView (ElementPath)<SAVisualizedViewPathProperty, SAVisualizedExtensionProperty>

@end

@interface UIScrollView (ElementPath)<SAVisualizedExtensionProperty>
@end

@interface UISwitch (ElementPath)<SAVisualizedViewPathProperty>
@end

@interface UIStepper (ElementPath)<SAVisualizedViewPathProperty>
@end

@interface UISlider (ElementPath)<SAVisualizedViewPathProperty>
@end

@interface UIPageControl (ElementPath)<SAVisualizedViewPathProperty>
@end

@interface WKWebView (ElementPath)<SAVisualizedViewPathProperty>

@end

@interface UIWindow (ElementPath)<SAVisualizedViewPathProperty>
@end

@interface UITableView (ElementPath)<SAVisualizedViewPathProperty>
@end

@interface UICollectionView (ElementPath)<SAVisualizedViewPathProperty>
@end

@interface UITableViewCell (ElementPath)<SAAutoTrackViewProperty>
@end

@interface UICollectionViewCell (ElementPath)<SAAutoTrackViewProperty>
@end

@interface UITableViewHeaderFooterView (ElementPath)
@end

@interface SAJSTouchEventView (ElementPath)<SAVisualizedViewPathProperty>
@end

@interface UIViewController (ElementPath)<SAVisualizedViewPathProperty>
@end

NS_ASSUME_NONNULL_END
