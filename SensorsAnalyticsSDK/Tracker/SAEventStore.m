//
// SAEventStore.m
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

#import "SAEventStore.h"
#import "SADatabase.h"

static void * const SAEventStoreContext = (void*)&SAEventStoreContext;

@interface SAEventStore ()

@property (nonatomic) NSUInteger count;

@property (nonatomic, strong) SADatabase *database;

/// store data in memory
@property (nonatomic, strong) NSMutableArray<SAEventRecord *> *messageCaches;

@end

@implementation SAEventStore

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        NSString *label = [NSString stringWithFormat:@"cn.sensorsdata.SAEventStore.%p", self];
        _serialQueue = dispatch_queue_create(label.UTF8String, DISPATCH_QUEUE_SERIAL);

        [self setupDatabase:filePath];
    }
    return self;
}

- (void)dealloc {
    [self.database removeObserver:self forKeyPath:@"isCreatedTable"];
}

- (void)setupDatabase:(NSString *)filePath {
    dispatch_async(self.serialQueue, ^{
        self.messageCaches = [NSMutableArray array];
        self.database = [[SADatabase alloc] initWithFilePath:filePath];
        [self.database open];
        
        [self.database addObserver:self forKeyPath:@"isCreatedTable" options:NSKeyValueObservingOptionNew context:SAEventStoreContext];

        self.count = [self.database messagesCount];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != SAEventStoreContext) {
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    if (![keyPath isEqualToString:@"isCreatedTable"]) {
        return;
    }
    if (![change[@"isCreatedTable"] boolValue] || self.messageCaches.count == 0) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        [self.database insertRecords:self.messageCaches];
    });
}

- (NSArray<SAEventRecord *> *)fetchRecords:(NSUInteger)recordSize {
    return [self.database fetchRecords:recordSize];
}

- (BOOL)insertRecords:(NSArray<SAEventRecord *> *)records {
    BOOL success = [self.database insertRecords:records];
    if (success) {
        self.count += records.count;
    }
    return success;
}

- (BOOL)insertRecord:(SAEventRecord *)record {
    BOOL success = [self.database insertRecord:record];
    if (success) {
        self.count++;
    }
    return success;
}

- (BOOL)deleteRecords:(NSArray<NSString *> *)recordIDs {
    BOOL success = [self.database deleteRecords:recordIDs];
    if (success) {
        self.count -= recordIDs.count;
    }
    return success;
}

- (BOOL)deleteAllRecords {
    BOOL success = [self.database deleteAllRecords];
    if (success) {
        self.count = 0;
    }
    return success;
}

- (void)fetchRecords:(NSUInteger)recordSize completion:(void (^)(NSArray<SAEventRecord *> *records))completion {
    dispatch_async(self.serialQueue, ^{
        completion([self.database fetchRecords:recordSize]);
    });
}

- (void)insertRecords:(NSArray<SAEventRecord *> *)records completion:(void (^)(BOOL))completion {
    dispatch_async(self.serialQueue, ^{
        BOOL success = [self.database insertRecords:records];
        if (success) {
            self.count += records.count;
        }
        completion(success);
    });
}

- (void)insertRecord:(SAEventRecord *)record completion:(void (^)(BOOL))completion {
    dispatch_async(self.serialQueue, ^{
        BOOL success = [self.database insertRecord:record];
        if (success) {
            self.count++;
        }
        completion(success);
    });
}

- (void)deleteRecords:(NSArray<NSString *> *)recordIDs completion:(void (^)(BOOL))completion {
    dispatch_async(self.serialQueue, ^{
        BOOL success = [self.database deleteRecords:recordIDs];
        if (success) {
            self.count -= recordIDs.count;
        }
        completion(success);
    });
}

- (void)deleteAllRecordsWithCompletion:(void (^)(BOOL))completion {
    dispatch_async(self.serialQueue, ^{
        BOOL success = [self.database deleteAllRecords];
        if (success) {
            self.count = 0;
        }
        completion(success);
    });
}

@end
