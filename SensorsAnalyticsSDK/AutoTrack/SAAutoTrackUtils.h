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
#import "UIView+AutoTrack.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAAutoTrackUtils : NSObject

#if UIKIT_DEFINE_AS_PROPERTIES
@property(class, nonatomic, readonly) UIViewController *currentViewController;
#else
+ (UIViewController *)currentViewController;
#endif

+ (UIViewController *)findNextViewControllerByResponder:(UIResponder *)responder;
+ (UIViewController *)findSuperViewControllerByView:(UIView *)view;

+ (nullable NSDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackView>)object viewController:(nullable UIViewController<SAAutoTrackViewController> *)viewController;

@end

NS_ASSUME_NONNULL_END
