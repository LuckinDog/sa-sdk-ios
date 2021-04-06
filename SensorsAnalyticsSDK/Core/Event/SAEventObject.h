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

#import <Foundation/Foundation.h>
#import "SAEventLibObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAEventObject : NSObject

@property (nonatomic, copy) NSString *event;
@property (nonatomic, strong) NSDictionary *properties;
@property (nonatomic, strong) SAEventLibObject *libObject;

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties;

- (NSDictionary *)generateJSONObject;

@end

@interface SACustomEventObject : SAEventObject

@end

@interface SASignUpEventObject : SAEventObject

@end

@interface SAAutoTrackEventObject : SAEventObject

@end

@interface SAPresetEventObject : SAEventObject

@end

@interface SAProfileEventObject : SAEventObject

@end

@interface SAH5EventObject : SAEventObject

@end

NS_ASSUME_NONNULL_END
