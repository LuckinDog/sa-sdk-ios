//
//  SAAutoTrackUtils.h
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
    

#import <UIKit/UIKit.h>
#import "SAAutoTrack.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAAutoTrackUtils : NSObject

#if UIKIT_DEFINE_AS_PROPERTIES
/// 返回当前的 ViewController
@property(class, nonatomic, readonly) UIViewController *currentViewController;
#else
+ (UIViewController *)currentViewController;
#endif

/**
 获取响应链中的下一个 UIViewController

 @param responder 响应链中的对象
 @return 下一个 ViewController
 */
+ (UIViewController *)findNextViewControllerByResponder:(UIResponder *)responder;

/**
 找到 view 所在的直接 ViewController

 @param view 需要寻找的 View
 @return SuperViewController
 */
+ (UIViewController *)findSuperViewControllerByView:(UIView *)view;

@end

#pragma mark -
@interface SAAutoTrackUtils (Property)

/**
 采集 ViewController 中的事件属性

 @param viewController 需要采集的 ViewController
 @return 事件中与 ViewController 相关的属性字典
 */
+ (NSDictionary<NSString *, NSString *> *)propertiesWithViewController:(UIViewController<SAAutoTrackViewController> *)viewController;

/**
 通过 AutoTrack 控件，获取事件的属性

 @param object 控件的对象，UIView 及其子类或 UIBarItem 的子类
 @return 事件属性字典
 */
+ (nullable NSDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackView>)object;

/**
 通过 AutoTrack 控件，获取事件的属性

 @param object 控件的对象，UIView 及其子类或 UIBarItem 的子类
 @param isIgnoredViewPath 是否采集控件的 ViewPath
 @return 事件属性字典
 */
+ (nullable NSDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackView>)object isIgnoredViewPath:(BOOL)isIgnoredViewPath;

/**
 通过 AutoTrack 控件，获取事件的属性

 @param object 控件的对象，UIView 及其子类或 UIBarItem 的子类
 @param viewController 控件所在的 ViewController，当为 nil 时，自动采集当前界面上的 ViewController
 @return 事件属性字典
 */
+ (nullable NSDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackView>)object viewController:(nullable UIViewController<SAAutoTrackViewController> *)viewController;

@end

#pragma mark -
@interface SAAutoTrackUtils (ViewPath)

+ (BOOL)isIgnoredViewPathForViewController:(UIViewController *)viewController;

+ (NSString *)viewIdentifierForView:(UIView *)view;
+ (NSString *)itemPathForResponder:(UIResponder *)responder;

+ (NSArray<NSString *> *)viewPathsForView:(UIView *)view;
+ (NSString *)viewPathForView:(UIView *)view atViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
