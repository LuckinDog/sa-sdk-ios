//
//  SARemoteConfigModel.m
//  SensorsAnalyticsSDK
//
// Created by wenquan on 2020/7/20.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "SARemoteConfigModel.h"
#import "SAValidator.h"

static id dictionaryValueForKey(NSDictionary *dic, NSString *key) {
    if (![SAValidator isValidDictionary:dic]) {
        return nil;
    }
    
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
        if ([self isAutoTrackModeValid:iMode]) {
            self.autoTrackMode = iMode;
        }
    }
}

- (BOOL)isAutoTrackModeValid:(NSInteger)autoTrackMode {
    BOOL valid = NO;
    if (autoTrackMode >= kSAAutoTrackModeDefault && autoTrackMode <= kSAAutoTrackModeEnabledAll) {
        valid = YES;
    }
    return valid;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithCapacity:3];
    mDic[@"disableSDK"] = [NSNumber numberWithBool:self.disableSDK];
    mDic[@"disableDebugMode"] = [NSNumber numberWithBool:self.disableDebugMode];
    mDic[@"autoTrackMode"] = [NSNumber numberWithInteger:self.autoTrackMode];
    return mDic;
}

- (NSString *)description {
    return [[NSString alloc] initWithFormat:@"<%@:%p>, disableSDK=%d, disableDebugMode=%d, autoTrackMode=%ld",self.class, self, self.disableSDK, self.disableDebugMode, (long)self.autoTrackMode];
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

- (NSString *)description {
    return [[NSString alloc] initWithFormat:@"<%@:%p>, event_v=%@, event_blackList=%@",self.class, self, self.version, self.blackList];
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
    return [[NSString alloc] initWithFormat:@"<%@:%p>, \n v=%@, \n configs=%@, \n event_config=%@, \n localLibVersion=%@",self.class, self, self.version, self.mainConfigModel, self.eventConfigModel, self.localLibVersion];
}

@end
