//
// SAEventObject.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/6.
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

#import "SAEventBuildStrategy.h"
#import "SAEventLibObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAEventObject : SAEventBuildStrategy

@property (nonatomic, strong) SAEventLibObject *libObject;

@property (nonatomic, assign) UInt64 currentSystemUpTime;
@property (nonatomic, assign) UInt64 timeStamp;

@property (nonatomic, strong) NSDictionary *dynamicSuperProperties;

#pragma mark - event
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *event;
@property (nonatomic, copy) NSString *loginId;
@property (nonatomic, copy) NSString *anonymousID;
@property (nonatomic, copy) NSString *distinctID;
@property (nonatomic, strong) NSNumber *track_id;
@property (nonatomic, copy) NSString *project;
@property (nonatomic, copy) NSString *token;

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties;

- (BOOL)isCanTrack;

- (NSDictionary *)generateJSONObject;

@end

@interface SASignUpEventObject : SAEventObject

@end

@interface SACustomEventObject : SAEventObject

@property (nonatomic, strong) NSMutableSet<NSString *> *trackChannelEventNames;

@end

@interface SAAutoTrackEventObject : SAEventObject

@end

@interface SAPresetEventObject : SAEventObject

@end

@interface SAProfileEventObject : SAEventObject

@end

@interface SAProfileIncrementEventObject : SAProfileEventObject

@end

@interface SAProfileAppendEventObject : SAProfileEventObject

@end

@interface SAH5EventObject : SAEventObject

@end

NS_ASSUME_NONNULL_END
