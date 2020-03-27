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
#import "SAIdentifierManager.h"

@interface SAIdentifierManagerTests : XCTestCase

@property (nonatomic, strong) SAIdentifierManager *manager;

@end

@implementation SAIdentifierManagerTests

- (void)setUp {

    _manager = [[SAIdentifierManager alloc] init];
    [_manager archiveLoginId:@"newId"];
}

- (void)testGetDistinctId {
    NSString *distinctId = _manager.distinctId;
    NSString *hardwareId = _manager.uniqueHardwareId;
    XCTAssertTrue([distinctId isEqualToString:hardwareId]);
}

- (void)testGetLoginId {
    NSString *loginId = _manager.loginId;
    XCTAssertTrue([loginId isEqualToString:@"newId"]);

    [_manager archiveLoginId:@"pyy_test_login_id"];
    NSString *newLoginId = _manager.loginId;
    XCTAssertTrue([newLoginId isEqualToString:@"pyy_test_login_id"]);

    [_manager archiveLoginId:nil];
    NSString *nilLoginId = _manager.loginId;
    XCTAssertNil(nilLoginId);
}

- (void)tearDown {

}

@end
