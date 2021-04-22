//
// SASuperPropertyTests.m
// SensorsAnalyticsTests
//
// Created by yuqiang on 2021/4/19.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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
#import "SASuperProperty.h"

@interface SASuperPropertyTests : XCTestCase

@property (nonatomic, strong) SASuperProperty *superPorperty;

@end

@implementation SASuperPropertyTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _superPorperty = [[SASuperProperty alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _superPorperty = nil;
}

- (void)testRegisterSuperProperties {
    [self.superPorperty registerSuperProperties:@{@"testRegister": @"testRegisterValue"}];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count > 0);
}

- (void)testClearSuperProperties {
    [self.superPorperty registerSuperProperties:@{@"testRegister": @"testRegisterValue"}];
    [self.superPorperty clearSuperProperties];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);
}

- (void)testRegisterSuperPropertiesForInvalid {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"123abc": @"123abcValue"}];
    XCTAssertTrue(self.superPorperty.currentSuperProperties.count == 0);
}

- (void)testRepeatRegisterSuperProperties {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"abc": @"abcValue"}];
    [self.superPorperty registerSuperProperties:@{@"ABC": @"ABCValue"}];
    NSDictionary *result = [self.superPorperty currentSuperProperties];
    XCTAssertTrue([@{@"ABC": @"ABCValue"} isEqualToDictionary:result]);
}

- (void)testRepeatRegisterSuperProperties2 {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"abc": @"abcValue", @"ABC": @"ABCValue"}];
    NSDictionary *result = [self.superPorperty currentSuperProperties];
    XCTAssertTrue([(@{@"abc":@"abcValue", @"ABC": @"ABCValue"}) isEqualToDictionary:result]);
}

- (void)testUnregisterSuperProperty {
    [self.superPorperty clearSuperProperties];
    [self.superPorperty registerSuperProperties:@{@"abc": @"abcValue", @"ABC": @"ABCValue"}];
    [self.superPorperty unregisterSuperProperty:@"ABC"];
    NSDictionary *result = [self.superPorperty currentSuperProperties];
    XCTAssertTrue([(@{@"abc": @"abcValue"}) isEqualToDictionary:result]);

    [self.superPorperty unregisterSuperProperty:@"abc"];
    NSDictionary *result2 = [self.superPorperty currentSuperProperties];
    XCTAssertTrue([(@{}) isEqualToDictionary:result2]);
}



- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
