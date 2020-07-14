//
// SAEventTracker.m
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

#import "SAEventTracker.h"
#import "SAEventFlush.h"
#import "SAEventStore.h"
#import "SADatabase.h"
#import "SANetwork.h"
#import "SAFileStore.h"
#import "SAJSONUtil.h"
#import "SALog.h"
#import "SAObject+SAConfigOptions.h"
#import "SACommonUtility.h"
#import "SAConstants+Private.h"

@interface SAEventTracker ()

@property (nonatomic, strong) SAEventStore *eventStore;

@property (nonatomic, strong) SAEventFlush *eventFlush;

@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation SAEventTracker

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _queue = queue;

        dispatch_async(self.queue, ^{
            self.eventStore = [[SAEventStore alloc] initWithFilePath:[SAFileStore filePath:@"message-v2"]];
            self.eventFlush = [[SAEventFlush alloc] init];
        });
    }
    return self;
}

- (void)trackEvent:(NSDictionary *)event flushType:(SAEventTrackerFlushType)type {
//    [self encryptionJSONObject:event];
    SAEventRecord *record = [[SAEventRecord alloc] initWithEvent:event type:@"POST"];
    [self.eventStore insertRecord:record];

    // 本地缓存的数据是否超过 flushBulkSize
    if (self.eventStore.count > self.flushBulkSize || type != SAEventTrackerFlushTypeNone) {
        [self flushWithType:type];
    }
}

- (BOOL)canFlush {
    // serverURL 是否有效
    if (self.eventFlush.serverURL.absoluteString.length == 0) {
        return NO;
    }
    // 判断当前网络类型是否符合同步数据的网络策略
    if (!([SACommonUtility currentNetworkType] & self.networkTypePolicy)) {
        return NO;
    }
    return YES;
}

- (void)encryptEventRecords:(NSArray<SAEventRecord *> *)records {

}

- (void)flushWithType:(SAEventTrackerFlushType)type {
    if (![self canFlush]) {
        return;
    }
    BOOL isFlushed = [self flushRecordsWithSize:type];
    if (isFlushed) {
        SALogInfo(@"Events flushed!");
    }
}

- (BOOL)flushRecordsWithSize:(NSUInteger)size {
    // 从数据库中查询数据
    NSArray<SAEventRecord *> *records = [self.eventStore selectRecords:size];
    if (records.count == 0) {
        return NO;
    }
    // 获取查询到的数据的 id
    NSMutableArray *recordIDs = [NSMutableArray arrayWithCapacity:records.count];
    for (SAEventRecord *record in records) {
        [recordIDs addObject:record.recordID];
    }
    // 更新数据状态
    [self.eventStore updateRecords:recordIDs status:SAEventRecordStatusFlush];

    // 加密
    [self encryptEventRecords:records];

    // flush
    __weak typeof(self) weakSelf = self;
    [self.eventFlush flushEventRecords:records isEncrypted:NO completion:^(BOOL success) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        void(^block)() = ^ {
            if (!success) {
                [strongSelf.eventStore updateRecords:recordIDs status:SAEventRecordStatusNone];
                return;
            }
            // 5. 删除数据
            [strongSelf.eventStore deleteRecords:recordIDs];

            [strongSelf flushRecordsWithSize:size];
        }
        if (sensorsdata_is_same_queue(strongSelf.queue)) {
            block();
        } else {
            dispatch_sync(strongSelf.queue, block);
        }
    }];
    return YES;
}

@end
