//
// SABaseEventObjectTests.m
// SensorsAnalyticsTests
//
// Created by yuqiang on 2021/4/23.
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
#import "SABaseEventObject.h"
#import "SensorsAnalyticsSDK.h"
#import "SAConstants+Private.h"

@interface SABaseEventObjectTests : XCTestCase

@end

@implementation SABaseEventObjectTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"" launchOptions:nil];
    [SensorsAnalyticsSDK startWithConfigOptions:options];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testEvent {
    // eventId 结构为 {eventName}_D3AC265B_3CC2_4C45_B8F0_3E05A83A9DAE_SATimer，新增后缀长度为 44
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSString *eventName = @"testEventName";
    NSString *uuidString = [NSUUID.UUID.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    object.eventId = [NSString stringWithFormat:@"%@_%@%@", eventName, uuidString, kSAEventIdSuffix];
    XCTAssertTrue([eventName isEqualToString:object.event]);
}

- (void)testEvent2 {
    // eventId 结构为 {eventName}_D3AC265B_3CC2_4C45_B8F0_3E05A83A9DAE_SATimer，新增后缀长度为 44
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSString *eventName = @"";
    NSString *uuidString = [NSUUID.UUID.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    object.eventId = [NSString stringWithFormat:@"%@_%@%@", eventName, uuidString, kSAEventIdSuffix];
    XCTAssertTrue([eventName isEqualToString:object.event]);
}

- (void)testEvent3 {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    XCTAssertNil(object.event);
}

- (void)testEvent4 {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    object.eventId = @"";
    XCTAssertTrue([@"" isEqualToString:object.event]);
}

- (void)testIsSignUp {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    XCTAssertFalse(object.isSignUp);
}

- (void)testValidateEventWithError {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNil(error);
}

- (void)testJSONObject {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSMutableDictionary *jsonObject = [object jsonObject];
    XCTAssertTrue(jsonObject.count > 0);
}

- (void)testJSONObject2 {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSMutableDictionary *jsonObject = [object jsonObject];
    NSDictionary *lib = jsonObject[kSAEventLib];
    XCTAssertTrue(lib.count > 0);
}

- (void)testAddEventProperties {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    [object addEventProperties:@{}];
    XCTAssertTrue([@{} isEqualToDictionary:object.properties]);
}

- (void)testAddEventProperties2 {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    [object addEventProperties:properties];
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddChannelProperties {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    [object addChannelProperties:@{}];
    XCTAssertTrue([@{} isEqualToDictionary:object.properties]);
}

- (void)testAddChannelProperties2 {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    [object addChannelProperties:properties];
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddModuleProperties {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    [object addModuleProperties:@{}];
    XCTAssertTrue([@{} isEqualToDictionary:object.properties]);
}

- (void)testAddModuleProperties2 {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    [object addModuleProperties:properties];
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddSuperProperties {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    [object addSuperProperties:@{}];
    XCTAssertTrue([@{} isEqualToDictionary:object.properties]);
}

- (void)testAddSuperProperties2 {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    [object addSuperProperties:properties];
    XCTAssertTrue(object.properties.count == 0);
}


- (void)testAddCustomProperties {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
}

- (void)testAddCustomProperties2 {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([properties isEqualToDictionary:object.properties]);
}

- (void)testAddCustomProperties3 {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"123abc": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNotNil(error);
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddCustomProperties4 {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"id": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNotNil(error);
    XCTAssertTrue(object.properties.count == 0);
}

- (void)testAddCustomProperties5 {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{@"time": @"abcValue", @"ddd": @[@"123"], @"fff": @(999)};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNotNil(error);
    XCTAssertTrue(object.properties.count == 0);
}

@end
