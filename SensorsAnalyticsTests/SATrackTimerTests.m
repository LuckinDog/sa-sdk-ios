//
// SATrackTimerTests.m
// SensorsAnalyticsTests
//
// Created by 彭远洋 on 2020/1/3.
// Copyright © 2020 SensorsData. All rights reserved.
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
#import "SATrackTimer.h"

#define second(x) (x * 1000)

@interface SATrackTimerTests : XCTestCase

@property (nonatomic, strong) SATrackTimer *timer;

@end

@implementation SATrackTimerTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _timer = [[SATrackTimer alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testNormalTimerEventDuration {
    NSString *eventName = @"testTimer";
    [_timer trackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer trackTimerPause:eventName currentSysUpTime:second(4)];
    [_timer trackTimerResume:eventName currentSysUpTime:second(6)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventName currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration floatValue], 4, 0.1);
}

- (void)testNormalTimerEnterBackgroundAndBecomeActive {
    NSString *eventName = @"testTimer";
    [_timer trackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer trackTimerPause:eventName currentSysUpTime:second(4)];
    [_timer pauseAllEventTimers:second(6)];
    [_timer resumeAllEventTimers:second(8)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventName currentSysUpTime:second(10)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
}

- (void)testNormalTimerMutipleInvokeStart {
    NSString *eventName = @"testTimer";
    [_timer trackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer trackTimerStart:eventName currentSysUpTime:second(4)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventName currentSysUpTime:second(6)];
    XCTAssertEqualWithAccuracy([duration floatValue], 4, 0.1);
}

- (void)testNormalTimerMutipleInvokePause {
    NSString *eventName = @"testTimer";
    [_timer trackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer trackTimerPause:eventName currentSysUpTime:second(4)];
    [_timer trackTimerPause:eventName currentSysUpTime:second(6)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventName currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
}

- (void)testNormalTimerMutipleInvokeResume {
    NSString *eventName = @"testTimer";
    [_timer trackTimerStart:eventName currentSysUpTime:second(2)];
    [_timer trackTimerPause:eventName currentSysUpTime:second(4)];
    [_timer trackTimerResume:eventName currentSysUpTime:second(6)];
    [_timer trackTimerResume:eventName currentSysUpTime:second(8)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventName currentSysUpTime:second(10)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
}

- (void)testCrossTimerEventDuration {
    NSString *eventName = @"testTimer";
    NSString *eventId1 = [_timer generateEventIdByEventName:eventName];
    NSString *eventId2 = [_timer generateEventIdByEventName:eventName];
    [_timer trackTimerStart:eventId1 currentSysUpTime:second(1)];
    [_timer trackTimerStart:eventId2 currentSysUpTime:second(2)];
    [_timer trackTimerPause:eventId1 currentSysUpTime:second(3)];
    [_timer trackTimerPause:eventId2 currentSysUpTime:second(4)];
    [_timer trackTimerResume:eventId1 currentSysUpTime:second(5)];
    [_timer trackTimerResume:eventId2 currentSysUpTime:second(6)];
    NSNumber *duration1 = [_timer eventDurationFromEventId:eventId1 currentSysUpTime:second(7)];
    NSNumber *duration2 = [_timer eventDurationFromEventId:eventId2 currentSysUpTime:second(8)];
    XCTAssertEqualWithAccuracy([duration1 floatValue], 4, 0.1);
    XCTAssertEqualWithAccuracy([duration2 floatValue], 4, 0.1);

    XCTAssertTrue([[_timer eventNameFromEventId:eventId1] isEqualToString:eventName]);
    XCTAssertTrue([[_timer eventNameFromEventId:eventId2] isEqualToString:eventName]);
}

- (void)testCrossTimerEnterBackgroundAndBecomeActive {
    NSString *eventName = @"testTimer";
    NSString *eventId = [_timer generateEventIdByEventName:eventName];
    [_timer trackTimerStart:eventId currentSysUpTime:second(2)];
    [_timer trackTimerPause:eventId currentSysUpTime:second(4)];
    [_timer pauseAllEventTimers:second(6)];
    [_timer resumeAllEventTimers:second(8)];
    NSNumber *duration = [_timer eventDurationFromEventId:eventId currentSysUpTime:second(10)];
    XCTAssertEqualWithAccuracy([duration floatValue], 2, 0.1);
}

@end
