//
// SATrackEventObjectTests.m
// SensorsAnalyticsTests
//
// Created by yuqiang on 2021/4/25.
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
#import "SATrackEventObject.h"
#import "SensorsAnalyticsSDK.h"
#import "SAConstants+Private.h"
#import "SAPresetProperty.h"

@interface SATrackEventObjectTests : XCTestCase

@end

@implementation SATrackEventObjectTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"" launchOptions:nil];
    [SensorsAnalyticsSDK startWithConfigOptions:options];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testEventId {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@"eventId"];
    XCTAssertTrue([@"eventId" isEqualToString:object.event]);
}

- (void)testValidateEvent {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@"eventId"];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNil(error);
}

- (void)testValidateEvent2 {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@(123)];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNotNil(error);
}

- (void)testValidateEvent3 {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@""];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNotNil(error);
}

- (void)testValidateEvent4 {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:nil];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNotNil(error);
}

- (void)testValidateEvent5 {
    SATrackEventObject *object = [[SATrackEventObject alloc] initWithEventId:@"123abc"];
    NSError *error = nil;
    [object validateEventWithError:&error];
    XCTAssertNotNil(error);
}

- (void)testAddEventProperties {
    SATrackEventObject *object = [[SATrackEventObject alloc] init];
    [object addEventProperties:@{}];
    XCTAssertTrue([@{} isEqualToDictionary:object.properties]);
}

- (void)testAddEventProperties2 {
    SATrackEventObject *object = [[SATrackEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ccc": @[@"123"]};
    [object addEventProperties:properties];
    XCTAssertTrue([properties isEqualToDictionary:object.properties]);
}

- (void)testAddModuleProperties {
    SATrackEventObject *object = [[SATrackEventObject alloc] init];
    [object addEventProperties:@{}];
    XCTAssertTrue([@{} isEqualToDictionary:object.properties]);
}

- (void)testAddModuleProperties2 {
    SATrackEventObject *object = [[SATrackEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ccc": @[@"123"]};
    [object addEventProperties:properties];
    XCTAssertTrue([properties isEqualToDictionary:object.properties]);
}

- (void)testAddSuperProperties {
    SATrackEventObject *object = [[SATrackEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", @"ccc": @[@"123"]};
    [object addSuperProperties:properties];
    XCTAssertTrue([properties isEqualToDictionary:object.properties]);
}

- (void)testAddSuperProperties2 {
    SATrackEventObject *object = [[SATrackEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", kSAEventPresetPropertyAppVersion: @"v2.3.0"};
    [object addSuperProperties:properties];
    XCTAssertTrue([properties isEqualToDictionary:object.properties]);
    XCTAssertTrue([@"v2.3.0" isEqualToString:object.lib.appVersion]);
}

- (void)testAddCustomProperties {
    SATrackEventObject *object = [[SATrackEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue"};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([kSALibMethodCode isEqualToString:object.properties[kSAEventPresetPropertyLibMethod]]);
    XCTAssertTrue([kSALibMethodCode isEqualToString:object.lib.method]);
}

- (void)testAddCustomProperties2 {
    SATrackEventObject *object = [[SATrackEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", kSAEventPresetPropertyLibMethod: @(123)};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([@(123) isEqualToNumber:object.properties[kSAEventPresetPropertyLibMethod]]);
    XCTAssertTrue([kSALibMethodCode isEqualToString:object.lib.method]);
}

- (void)testAddCustomProperties3 {
    SATrackEventObject *object = [[SATrackEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", kSAEventPresetPropertyLibMethod: @"test_lib"};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([kSALibMethodCode isEqualToString:object.properties[kSAEventPresetPropertyLibMethod]]);
    XCTAssertTrue([kSALibMethodCode isEqualToString:object.lib.method]);
}

- (void)testAddCustomProperties4 {
    SATrackEventObject *object = [[SATrackEventObject alloc] init];
    NSDictionary *properties = @{@"abc": @"abcValue", kSAEventPresetPropertyLibMethod: kSALibMethodAuto};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.properties[kSAEventPresetPropertyLibMethod]]);
    XCTAssertTrue([kSALibMethodAuto isEqualToString:object.lib.method]);
}

- (void)testAddReferrerTitleProperty {
    SATrackEventObject *object = [[SATrackEventObject alloc] init];
    [object addReferrerTitleProperty:@"test_referrer_title"];
    XCTAssertTrue([@"test_referrer_title" isEqualToString:object.properties[kSAEeventPropertyReferrerTitle]]);
}

- (void)testAddDurationProperty {
    SATrackEventObject *object = [[SATrackEventObject alloc] init];
    [object addDurationProperty:@(123)];
    XCTAssertTrue([@(123) isEqualToNumber:object.properties[@"event_duration"]]);
}

- (void)testAddDurationProperty2 {
    SATrackEventObject *object = [[SATrackEventObject alloc] init];
    [object addDurationProperty:nil];
    XCTAssertNil(object.properties[@"event_duration"]);
}

@end
