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

- (void)testAddCustomProperties {
    SABaseEventObject *object = [[SABaseEventObject alloc] init];
    NSDictionary *properties = @{};
    NSError *error = nil;
    [object addCustomProperties:properties error:&error];
    XCTAssertNil(error);
}



@end
