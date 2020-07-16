//
//  SARemoteConfigModel.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/4/24.
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

#import "SARemoteConfigModel.h"

static BOOL isAutoTrackModeValid(NSInteger autoTrackMode) {
    BOOL valid = NO;
    if (autoTrackMode >= kSAAutoTrackModeDefault && autoTrackMode <= kSAAutoTrackModeEnabledAll) {
        valid = YES;
    }
    return valid;
}

static id dictionaryValueForKey(NSDictionary *dic, NSString *key) {
    id value = dic[key];
    return (value && ![value isKindOfClass:NSNull.class]) ? value : nil;
}

@implementation SARemoteMainConfigModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.disableSDK = [dictionaryValueForKey(dictionary, @"disableSDK") boolValue];
        self.disableDebugMode = [dictionaryValueForKey(dictionary, @"disableDebugMode") boolValue];
        [self setupAutoTrackMode:dictionary];
    }
    return self;
}

- (void)setupAutoTrackMode:(NSDictionary *)dictionary {
    self.autoTrackMode = kSAAutoTrackModeDefault;

    NSNumber *autoTrackMode = dictionaryValueForKey(dictionary, @"autoTrackMode");
    if (autoTrackMode != nil) {
        NSInteger iMode = autoTrackMode.integerValue;
        if (isAutoTrackModeValid(iMode)) {
            self.autoTrackMode = iMode;
        }
    }
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithCapacity:3];
    mDic[@"disableSDK"] = [NSNumber numberWithBool:self.disableSDK];
    mDic[@"disableDebugMode"] = [NSNumber numberWithBool:self.disableDebugMode];
    mDic[@"autoTrackMode"] = [NSNumber numberWithInteger:self.autoTrackMode];
    return mDic;
}

@end

@implementation SARemoteEventConfigModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.version = dictionaryValueForKey(dictionary, @"v");
        self.blackList = dictionaryValueForKey(dictionary, @"event_blacklist");
    }
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithCapacity:2];
    mDic[@"v"] = self.version;
    mDic[@"event_blacklist"] = self.blackList;
    return mDic;
}

@end

@implementation SARemoteConfigModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        self.version = dictionaryValueForKey(dictionary, @"v");
        self.localLibVersion = dictionaryValueForKey(dictionary, @"localLibVersion");
        self.mainConfigModel = [[SARemoteMainConfigModel alloc] initWithDictionary:dictionaryValueForKey(dictionary, @"configs")];
        self.eventConfigModel = [[SARemoteEventConfigModel alloc] initWithDictionary:dictionaryValueForKey(dictionary, @"event_config")];
    }
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithCapacity:4];
    mDic[@"v"] = self.version;
    mDic[@"configs"] = [self.mainConfigModel toDictionary];
    mDic[@"event_config"] = [self.eventConfigModel toDictionary];
    mDic[@"localLibVersion"] = self.localLibVersion;
    return mDic;
}

- (NSString *)description {
    return [[NSString alloc] initWithFormat:@"<%@:%p>,v=%@,disableSDK=%d,disableDebugMode=%d,autoTrackMode=%ld",self.class, self, self.version, self.mainConfigModel.disableSDK, self.mainConfigModel.disableDebugMode, (long)self.mainConfigModel.autoTrackMode];
}

@end
