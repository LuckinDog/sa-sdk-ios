//
// SAReadWriteLock.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/5/21.
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

#import "SAReadWriteLock.h"
#import "SALog.h"

@interface SAReadWriteLock ()

@property (nonatomic, strong) dispatch_queue_t concurentQueue;

@end

@implementation SAReadWriteLock

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *concurentQueueLabel = [NSString stringWithFormat:@"com.sensorsdata.readWriteLock.%p", self];
        self.concurentQueue = dispatch_queue_create([concurentQueueLabel UTF8String], DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)read:(DISPATCH_NOESCAPE dispatch_block_t)block {
    if (block) {
        dispatch_sync(self.concurentQueue, block);
    }
}

- (void)write:(DISPATCH_NOESCAPE dispatch_block_t)block {
    if (block) {
        dispatch_barrier_sync(self.concurentQueue, block);
    }
}

@end
