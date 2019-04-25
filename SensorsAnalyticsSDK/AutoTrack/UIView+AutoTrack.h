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
#import "SAAutoTrack.h"

#pragma mark - UIView

@interface UIView (AutoTrack) <SAAutoTrackView, SAAutoTrackViewPath>
@end

@interface UILabel (AutoTrack) <SAAutoTrackView>
@end

@interface UIImageView (AutoTrack) <SAAutoTrackView>
@end

@interface UITextView (AutoTrack) <SAAutoTrackView>
@end

@interface UITabBar (AutoTrack) <SAAutoTrackView>
@end

@interface UISearchBar (AutoTrack) <SAAutoTrackView>
@end

@interface UITableViewHeaderFooterView (AutoTrack) <SAAutoTrackViewPath>
@end

#pragma mark - UIControl

@interface UIButton (AutoTrack) <SAAutoTrackView>
@end

@interface UISwitch (AutoTrack) <SAAutoTrackView>
@end

@interface UIStepper (AutoTrack) <SAAutoTrackView>
@end

@interface UISegmentedControl (AutoTrack) <SAAutoTrackView>
@end

#pragma mark - UIBarItem

@interface UIBarItem (AutoTrack) <SAAutoTrackView>
@end

@interface UIBarButtonItem (AutoTrack) <SAAutoTrackView>
@end

@interface UITabBarItem (AutoTrack) <SAAutoTrackView>
@end

