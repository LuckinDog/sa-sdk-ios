//
// SAGestureViewProcessorContext.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/10.
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

#import "SAGestureViewProcessorContext.h"
#import "SAAlertGestureViewProcessor.h"

@interface SAGestureViewProcessorContext ()

@property (nonatomic, strong) id<SAGestureViewProcessor> processor;
@property (nonatomic, strong) UIGestureRecognizer *gesture;

@end

@implementation SAGestureViewProcessorContext

- (instancetype)initWithGesture:(UIGestureRecognizer *)gesture {
    if (self = [super init]) {
        self.gesture = gesture;
        NSString *viewType = NSStringFromClass(gesture.view.class);
        if ([viewType isEqualToString:@"_UIAlertControllerView"]) {
            self.processor = [[SALegacyAlertGestureViewProcessor alloc] init];
        } else if ([viewType isEqualToString:@"_UIAlertControllerInterfaceActionGroupView"]) {
            self.processor = [[SANewAlertGestureViewProcessor alloc] init];
        } else if ([viewType isEqualToString:@"_UIContextMenuActionsListView"]) {
            self.processor = [[SAMenuGestureViewProcessor alloc] init];
        } else {
            self.processor = [[SAGeneralGestureViewProcessor alloc] init];
        }
    }
    return self;
}

- (BOOL)isTrackable {
    return [self.processor isTrackableWithGesture:self.gesture];
}

- (UIView *)trackableView {
    return [self.processor trackableViewWithGesture:self.gesture];
}

@end
