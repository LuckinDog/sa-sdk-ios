//
//  UIGestureRecognizer+AutoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2018/10/25.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIGestureRecognizer+AutoTrack.h"
#import "SAGestureRecognizerTarget.h"
#import <objc/runtime.h>
#import "SASwizzle.h"
#import "SALog.h"

static void *const kSAGestureCanTrackKey = (void *)&kSAGestureCanTrackKey;
static void *const kSAGestureTargetKey = (void *)&kSAGestureTargetKey;

@interface UIGestureRecognizer (AutoTrack)

@property (nonatomic, strong) SAGestureRecognizerTarget *sensorsdata_trackTarget;

@end

@implementation UIGestureRecognizer (AutoTrack)

+ (NSArray <NSString *>*)sensorsdata_canTrackGestureClasses {
    return @[
                NSStringFromClass(UITapGestureRecognizer.class),
                NSStringFromClass(UILongPressGestureRecognizer.class),
                @"_UIContextMenuSelectionGestureRecognizer",
            ];
}

+ (void)sensorsdata_enableGestureTrack {
    static dispatch_once_t onceTokenGesture;
    dispatch_once(&onceTokenGesture, ^{
        NSError *error = NULL;
        [UIGestureRecognizer sa_swizzleMethod:@selector(addTarget:action:)
                                   withMethod:@selector(sensorsdata_addTarget:action:)
                                        error:&error];
        [UIGestureRecognizer sa_swizzleMethod:@selector(initWithTarget:action:)
                                   withMethod:@selector(sensorsdata_initWithTarget:action:)
                                        error:&error];
        if (error) {
            SALogError(@"Failed to swizzle Target on UIGestureRecognizer. Details: %@", error);
        }
    });
}

- (BOOL)sensorsdata_canTrack {
    // 指定的手势可以采集(不包含其子类)
    if ([self.class.sensorsdata_canTrackGestureClasses containsObject:NSStringFromClass(self.class)]) {
        return YES;
    }
    // 用户配置的手势可以采集
    NSNumber *number = objc_getAssociatedObject(self, kSAGestureCanTrackKey);
    return  [number boolValue];
}

- (void)setSensorsdata_canTrack:(BOOL)sensorsdata_canTrack {
    NSNumber *number = [NSNumber numberWithBool:sensorsdata_canTrack];
    objc_setAssociatedObject(self, kSAGestureCanTrackKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SAGestureRecognizerTarget *)sensorsdata_trackTarget {
    SAGestureRecognizerTarget *trackTarget = objc_getAssociatedObject(self, kSAGestureTargetKey);
    if (!trackTarget) {
        self.sensorsdata_trackTarget = [[SAGestureRecognizerTarget alloc] init];
    }
    return objc_getAssociatedObject(self, kSAGestureTargetKey);
}

- (void)setSensorsdata_trackTarget:(SAGestureRecognizerTarget *)sensorsdata_trackTarget {
    objc_setAssociatedObject(self, kSAGestureTargetKey, sensorsdata_trackTarget, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (instancetype)sensorsdata_initWithTarget:(id)target action:(SEL)action {
    [self sensorsdata_initWithTarget:target action:action];
    [self removeTarget:target action:action];
    [self addTarget:target action:action];
    return self;
}

- (void)sensorsdata_addTarget:(id)target action:(SEL)action {
    // Track 事件需要在原有事件之前触发(原有事件中更改页面内容,会导致部分内容获取不准确)
    [self sensorsdata_addTrackAction];
    [self sensorsdata_addTarget:target action:action];
}

- (void)sensorsdata_addTrackAction {
    // 校验是否是允许采集的手势
    if (!self.sensorsdata_canTrack) return;
    [self sensorsdata_addTarget:self.sensorsdata_trackTarget action:@selector(trackGestureRecognizerAppClick:)];
}

@end
