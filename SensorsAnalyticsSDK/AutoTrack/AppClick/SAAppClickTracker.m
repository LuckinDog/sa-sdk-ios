//
// SAAppClickTracker.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/4/27.
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

#import "SAAppClickTracker.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAAutoTrackProperty.h"
#import "SAConstants.h"
#import "SAValidator.h"
#import "SAAutoTrackUtils.h"
#import "UIView+AutoTrack.h"
#import "UIViewController+AutoTrack.h"
#import "SALog.h"
#import "SAModuleManager.h"

static NSString * const kSAEventPropertyElementID = @"$element_id";
static NSString * const kSAEventPropertyElementType = @"$element_type";
static NSString * const kSAEventPropertyElementContent = @"$element_content";
static NSString * const kSAEventPropertyElementPosition = @"$element_position";

//static NSString * const kSAEventNameAppClick = @"$AppClick";

@interface SAAppClickTracker ()

@property (nonatomic, strong) NSMutableArray<Class> *ignoredViewTypeList;

@end

@implementation SAAppClickTracker

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _ignoredViewTypeList = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Override

+ (NSString *)eventName {
    return kSAEventNameAppClick;
}

#pragma mark - Public Methods

- (void)autoTrackWithView:(UIView *)view properties:(NSDictionary<NSString *, id> * _Nullable)properties {
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
    
    [SAModuleManager.sharedInstance visualPropertiesWithView:view completionHandler:^(NSDictionary * _Nullable visualProperties) {
        if (visualProperties) {
            [eventProperties addEntriesFromDictionary:visualProperties];
        }
        
        [self trackAutoTrackEventWithEventId:kSAEventNameAppClick properties:eventProperties];
    }];
}

- (void)trackWithView:(UIView *)view properties:(NSDictionary<NSString *,id> *)properties {
    @try {
        if (view == nil) {
            return;
        }
        NSMutableDictionary *eventProperties = [[NSMutableDictionary alloc]init];
        [eventProperties addEntriesFromDictionary:[SAAutoTrackUtils propertiesWithAutoTrackObject:view isCodeTrack:YES]];
        if ([SAValidator isValidDictionary:properties]) {
            [eventProperties addEntriesFromDictionary:properties];
        }

        // 添加自定义属性
        [SAModuleManager.sharedInstance visualPropertiesWithView:view completionHandler:^(NSDictionary * _Nullable visualProperties) {
            if (visualProperties) {
                [eventProperties addEntriesFromDictionary:visualProperties];
            }
            SAPresetEventObject *object = [[SAPresetEventObject alloc] initWithEventId:kSAEventNameAppClick];
            [SensorsAnalyticsSDK.sharedInstance asyncTrackEventObject:object properties:eventProperties];
        }];
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
}

- (void)ignoreViewType:(Class)aClass {
    [self.ignoredViewTypeList addObject:aClass];
}

- (BOOL)isViewTypeIgnored:(Class)aClass {
    for (Class obj in self.ignoredViewTypeList) {
        if ([aClass isSubclassOfClass:obj]) {
            return YES;
        }
    }
    return NO;
}

@end
