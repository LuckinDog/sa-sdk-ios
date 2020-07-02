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
//#import "SAConstants.h"

NSUInteger const SAEventFlushRecordSize = 50;

@interface SAEventTracker ()

@property (nonatomic, strong) SAEventStore *eventStore;

@property (nonatomic, strong) SAEventFlush *eventFlush;

@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) dispatch_semaphore_t flushSemaphore;

@end

@implementation SAEventTracker

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _queue = queue;

        _eventStore = [[SAEventStore alloc] initWithFilePath:[SAFileStore filePath:@"message-v2"]];
        _eventFlush = [[SAEventFlush alloc] init];
    }
    return self;
}

- (dispatch_semaphore_t)flushSemaphore {
    if (!_flushSemaphore) {
        _flushSemaphore = dispatch_semaphore_create(0);
    }
    return _flushSemaphore;
}

- (void)trackEvent:(NSDictionary *)event flushType:(SAEventTrackerFlushType)type {
    NSString *content = [[NSString alloc] initWithData:[SAJSONUtil JSONSerializeObject:event] encoding:NSUTF8StringEncoding];
    SAEventRecord *record = [[SAEventRecord alloc] initWithContent:content type:@"POST"];
    [self.eventStore insertRecord:record];

    dispatch_async(self.queue, ^{
        [self flushWithType:type];
    });
}

- (BOOL)canFlushWithType:(SAEventTrackerFlushType)type {
    // serverURL 是否有效
    if (self.eventFlush.serverURL.absoluteString.length == 0) {
        return NO;
    }
    // 判断当前网络类型是否符合同步数据的网络策略
    if (!([SACommonUtility currentNetworkType] & self.networkTypePolicy)) {
        return NO;
    }
    // 本地缓存的数据是否超过 flushBulkSize
    BOOL isGreaterSize = self.eventStore.count > self.flushBulkSize;
    // 是否需要 flush
    BOOL isFlushType = type != SAEventTrackerFlushTypeNone;
    return isGreaterSize || isFlushType;
}

- (void)encryptEventRecords:(NSArray<SAEventRecord *> *)records {

}

- (void)flushEventRecords:(NSArray<SAEventRecord *> *)records isEncrypted:(BOOL)isEncrypted completion:(void (^)(BOOL success))completion {
    // 当在程序终止或 debug 模式下，使用线程锁
    BOOL isWait = self.flushBeforeTerminate || self.debugMode != SensorsAnalyticsDebugOff;
    [self.eventFlush flushEventRecords:records isEncrypted:NO completion:^(BOOL success) {
        if (isWait) {
            dispatch_semaphore_signal(self.flushSemaphore);
        }

        dispatch_async(self.queue, ^{
            completion(success);
        });
    }];
    if (isWait) {
        dispatch_semaphore_wait(self.flushSemaphore, DISPATCH_TIME_FOREVER);
    }
}

- (void)flushWithType:(SAEventTrackerFlushType)type {
    // 判断是否可以 flush
    if (![self canFlushWithType:type]) {
        return;
    }

    // 从数据库中查询数据
    NSArray<SAEventRecord *> *records = [self.eventStore selectRecords:type];
    if (records.count == 0) {
        return;
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
    [self flushEventRecords:records isEncrypted:NO completion:^(BOOL success) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!success) {
            [strongSelf.eventStore updateRecords:recordIDs status:SAEventRecordStatusNone];
            return;
        }
        // 5. 删除数据
        [strongSelf.eventStore deleteRecords:recordIDs];
        SALogError(@"+++++++++++++++%@", recordIDs);
        SALogDebug(@"===============%ld", strongSelf.eventStore.count);

        [strongSelf flushWithType:type];
    }];
}

@end
