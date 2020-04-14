//
// SAIdentifierManagerTests.m
// SensorsAnalyticsTests
//
// Created by 彭远洋 on 2020/3/26.
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

#import <XCTest/XCTest.h>
#import "SAIdentifier.h"

void *QueueTag = &QueueTag;
void serial_async(dispatch_queue_t queue, DISPATCH_NOESCAPE dispatch_block_t block) {
    if (dispatch_get_specific(QueueTag)) {
        block();
    } else {
        dispatch_async(queue, block);
    }
}

@interface SAIdentifierTests : XCTestCase

@property (nonatomic, strong) SAIdentifier *identifier;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@end

@implementation SAIdentifierTests

- (void)setUp {

    NSString *label = [NSString stringWithFormat:@"sensorsdata.serialQueue.%p", self];
    _serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(_serialQueue, QueueTag, &QueueTag, NULL);

    _identifier = [[SAIdentifier alloc] initWithGlobalQueue:_serialQueue];
    [_identifier identify:@"0000-0000-0000-000000000"];
    [_identifier logout];
}

- (void)testIdentifyFront {
    // 重置 identifier 模拟初始化 SDK
    _identifier = [[SAIdentifier alloc] initWithGlobalQueue:_serialQueue];

    serial_async(self.serialQueue, ^{
        [_identifier identify:@"new_identify"];
    });

    serial_async(self.serialQueue, ^{
        XCTAssertTrue([_identifier.anonymousId isEqualToString:@"new_identify"]);
    });

    serial_async(self.serialQueue, ^{
        XCTAssertTrue([_identifier.distinctId isEqualToString:@"new_identify"]);
    });

    serial_async(self.serialQueue, ^{
        XCTAssertTrue([_identifier.originalId isEqualToString:@"0000-0000-0000-000000000"]);
    });
}

- (void)testIdentifyBack {
    // 重置 identifier 模拟初始化 SDK
    _identifier = [[SAIdentifier alloc] initWithGlobalQueue:_serialQueue];

    // 测试设置内容为空 case
    serial_async(self.serialQueue, ^{
        [_identifier identify:@""];
    });

    serial_async(self.serialQueue, ^{
        XCTAssertTrue([_identifier.anonymousId isEqualToString:@"0000-0000-0000-000000000"]);
    });
}

- (void)testLoginFront {
    // 重置 identifier 模拟初始化 SDK
    _identifier = [[SAIdentifier alloc] initWithGlobalQueue:_serialQueue];

    NSString *loginId = _identifier.loginId;
    XCTAssertNil(loginId);

    __block NSInteger count = 0;

    // 模拟 track_signup 事件
    dispatch_block_t completion = ^{
        serial_async(self.serialQueue, ^{
            count++;
            XCTAssertTrue(count == 1);
        });
    };

    // 模拟调用 login 方法后触发 track_signup 事件
    serial_async(self.serialQueue, ^{
        [_identifier login:@"new_login_id"];
    });

    // 事件在 track_signup 事件后触发，count 从 2 开始累加
    for (int i = 0; i < 10; i++) {
        serial_async(self.serialQueue, ^{
            count++;
            XCTAssertTrue(count == i + 2);
        });
    }

    serial_async(self.serialQueue, ^{
        XCTAssertTrue([_identifier.loginId isEqualToString:@"new_login_id"]);
    });

    serial_async(self.serialQueue, ^{
        XCTAssertTrue([_identifier.distinctId isEqualToString:@"new_login_id"]);
    });

    serial_async(self.serialQueue, ^{
        XCTAssertTrue([_identifier.originalId isEqualToString:@"0000-0000-0000-000000000"]);
    });
}

- (void)testLoginBack {
    // 重置 identifier 模拟初始化 SDK
    _identifier = [[SAIdentifier alloc] initWithGlobalQueue:_serialQueue];

    // 模拟调用 login 方法后触发 track_signup 事件
    serial_async(self.serialQueue, ^{
        [_identifier login:@""];
    });

    serial_async(self.serialQueue, ^{
        XCTAssertNil(_identifier.loginId);
    });

    serial_async(self.serialQueue, ^{
        XCTAssertTrue([_identifier.distinctId isEqualToString:@"0000-0000-0000-000000000"]);
    });

    serial_async(self.serialQueue, ^{
        XCTAssertNil(_identifier.originalId);
    });
}

- (void)testResetAnonymousId {
    serial_async(self.serialQueue, ^{
        XCTAssertTrue([_identifier.anonymousId isEqualToString:@"0000-0000-0000-000000000"]);
    });

    serial_async(self.serialQueue, ^{
        [_identifier resetAnonymousId];
        XCTAssertTrue([_identifier.anonymousId isEqualToString:[SAIdentifier generateUniqueHardwareId]]);
    });
}

- (void)testLogout {
    // 模拟 track_signup 事件
    dispatch_block_t completion = ^{
        serial_async(self.serialQueue, ^{
            XCTAssertTrue([self->_identifier.loginId isEqualToString:@"new_login_id"]);
        });
    };

    serial_async(self.serialQueue, ^{
        [_identifier login:@"new_login_id"];
    });

    serial_async(self.serialQueue, ^{
        [_identifier logout];
        XCTAssertNil(_identifier.loginId);
    });

    serial_async(self.serialQueue, ^{
        XCTAssertTrue([_identifier.distinctId isEqualToString:@"0000-0000-0000-000000000"]);
    });

    serial_async(self.serialQueue, ^{
        XCTAssertTrue([_identifier.originalId isEqualToString:@"0000-0000-0000-000000000"]);
    });
}

@end
