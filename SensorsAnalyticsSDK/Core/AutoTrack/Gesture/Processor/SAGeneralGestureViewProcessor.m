//
// SAGeneralGestureViewProcessor.m
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

#import "SAGeneralGestureViewProcessor.h"
#import "SAAlertGestureViewProcessor.h"
#import "UIGestureRecognizer+SAAutoTrack.h"
#import "SAGestureViewIgnore.h"

@interface SAGeneralGestureViewProcessor ()

@property (nonatomic, strong) UIGestureRecognizer *gesture;

@end

@implementation SAGeneralGestureViewProcessor

- (instancetype)initWithGesture:(UIGestureRecognizer *)gesture {
    if (self = [super init]) {
        self.gesture = gesture;
    }
    return self;
}

- (BOOL)isTrackable {
    if (self.gesture.state != UIGestureRecognizerStateEnded) {
        return NO;
    }
    if ([SAGestureViewIgnore ignoreWithView:self.gesture.view]) {
        return NO;
    }
    if ([SAGestureTargetActionPair filterValidPairsFrom:self.gesture.sensorsdata_targetActionPairs].count == 0) {
        return NO;
    }
    return YES;
}

- (UIView *)trackableView {
    return self.gesture.view;
}

@end

@implementation SAGeneralGestureViewProcessor (SAFactory)

+ (SAGeneralGestureViewProcessor *)processorWithGesture:(UIGestureRecognizer *)gesture {
    NSString *viewType = NSStringFromClass(gesture.view.class);
    if ([viewType isEqualToString:@"_UIAlertControllerView"]) {
        return [[SALegacyAlertGestureViewProcessor alloc] initWithGesture:gesture];
    }
    if ([viewType isEqualToString:@"_UIAlertControllerInterfaceActionGroupView"]) {
        return [[SANewAlertGestureViewProcessor alloc] initWithGesture:gesture];
    }
    if ([viewType isEqualToString:@"_UIContextMenuActionsListView"]) {
        return [[SAMenuGestureViewProcessor alloc] initWithGesture:gesture];
    }
    return [[SAGeneralGestureViewProcessor alloc] initWithGesture:gesture];
}

@end
