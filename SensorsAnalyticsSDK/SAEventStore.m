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

static void * const MyClassKVOContext = (void*)&MyClassKVOContext;

@interface SAEventStore ()

@property (nonatomic) NSUInteger count;

@property (nonatomic, strong) SADatabase *database;

/// store data in memory
@property (nonatomic, strong) NSMutableArray<NSString *> *messageCaches;

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

- (void)setupDatabase:(NSString *)filePath {
    dispatch_async(self.serialQueue, ^{
        self.messageCaches = [NSMutableArray array];
        self.database = [[SADatabase alloc] initWithFilePath:filePath];
        [self.database addObserver:self forKeyPath:@"isCreatedTable" options:NSKeyValueObservingOptionNew context:nil];
        self.count = [self.database count];
    });
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    if (context == <#context#>) {
//        <#code to be executed upon observing keypath#>
//    } else {
//        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//    }
//}

- (void)fetchRecords:(NSUInteger)recordSize completion:(void (^)(NSArray<SAEventRecord *> *records))completion {
    dispatch_async(self.serialQueue, ^{

    });
}

- (void)insertRecord:(SAEventRecord *)record completion:(void (^)(BOOL success))completion {
    dispatch_async(self.serialQueue, ^{

    });
}

- (void)insertRecords:(NSArray<SAEventRecord *> *)records completion:(void (^)(BOOL success))completion {
    dispatch_async(self.serialQueue, ^{

    });
}

- (void)deleteRecords:(NSArray<NSString *> *)recordIDs completion:(void (^)(BOOL success))completion {
    dispatch_async(self.serialQueue, ^{

    });
}

- (void)deleteAllRecordsWithCompletion:(void (^)(BOOL success))completion {
    dispatch_async(self.serialQueue, ^{

    });
}

@end
