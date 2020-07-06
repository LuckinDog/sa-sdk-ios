//
// SAEventRecord.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/6/18.
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

#import "SAEventRecord.h"
#import "SAJSONUtil.h"

@implementation SAEventRecord {
    NSMutableDictionary *_event;
}

static long recordIndex = 0;

- (instancetype)initWithEvent:(NSDictionary *)event type:(NSString *)type {
    if (self = [super init]) {
        _recordID = [NSString stringWithFormat:@"%ld", recordIndex];
        _event = [event mutableCopy];
        _type = type;
    }
    return self;
}

- (instancetype)initWithRecordID:(NSString *)recordID content:(NSString *)content {
    if (self = [super init]) {
        _recordID = recordID;
        _content = content;
    }
    return self;
}

- (NSString *)content {
    if (!_content && _event) {
        NSData *data = [SAJSONUtil JSONSerializeObject:self.event];
        _content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return _content;
}

- (NSDictionary *)event {
    if (!_event && _content.length > 0) {
        NSData *jsonData = [self.content dataUsingEncoding:NSUTF8StringEncoding];
        if (jsonData) {
            _event = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
        }
    }
    return _event;
}

- (void)addFlushTime {
    _content = nil;
    NSMutableDictionary *dic = [self.event mutableCopy];
    UInt64 time = [[NSDate date] timeIntervalSince1970] * 1000;
    dic[self.isEncrypted ? @"flush_time" : @"_flush_time"] = @(time);
    self.event = dic;
}

@end
