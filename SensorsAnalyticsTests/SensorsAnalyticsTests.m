//
//  SensorsAnalyticsTests.m
//  SensorsAnalyticsTests
//
//  Created by 张敏超 on 2019/3/12.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <XCTest/XCTest.h>
#import "SAConfigOptions.h"
#import "SensorsAnalyticsSDK.h"
#import "MessageQueueBySqlite.h"

@interface SensorsAnalyticsTests : XCTestCase
@property (nonatomic, weak) SensorsAnalyticsSDK *sensorsAnalytics;
@end

@interface SensorsAnalyticsSDK()
@property (atomic, strong) MessageQueueBySqlite *messageQueue;
@end

@implementation SensorsAnalyticsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.sensorsAnalytics = [SensorsAnalyticsSDK sharedInstance];
    if (!self.sensorsAnalytics) {
        SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"" launchOptions:nil];
        [SensorsAnalyticsSDK sharedInstanceWithConfig:options];
        self.sensorsAnalytics = [SensorsAnalyticsSDK sharedInstance];
    }
}

- (void)tearDown {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat"
    [self.sensorsAnalytics trackEventCallback:nil];
#pragma clang diagnostic pop
    self.sensorsAnalytics = nil;
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

#pragma mark - fix bug
// 调用 Profile 相关的方法时，事件名称为 nil，不调用 callback
- (void)testProfileEventWithoutCallback {
    __block BOOL isTrackEventCallbackExecuted = NO;
    [[SensorsAnalyticsSDK sharedInstance] trackEventCallback:^BOOL(NSString * _Nonnull eventName, NSMutableDictionary<NSString *,id> * _Nonnull properties) {
        isTrackEventCallbackExecuted = YES;
        return YES;
    }];
    [[SensorsAnalyticsSDK sharedInstance] set:@"avatar_url" to:@"http://www.sensorsdata.cn"];
    sleep(0.5);
    XCTAssertFalse(isTrackEventCallbackExecuted);
}

#pragma mark - event
- (void)testItemSet {
    NSInteger lastCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
    [[SensorsAnalyticsSDK sharedInstance] itemSetWithType:@"itemSet0517" itemId:@"itemId0517" properties:@{@"itemSet":@"acsdfgvzscd"}];
    
    sleep(1);
    
    NSInteger newCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
    BOOL insertSucceed = lastCount == newCount - 1;
    XCTAssertTrue(insertSucceed);
}

- (void)testItemDelete {
    NSInteger lastCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
    [[SensorsAnalyticsSDK sharedInstance] itemDeleteWithType:@"itemSet0517" itemId:@"itemId0517"];
    
    sleep(1);
    
    NSInteger newCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
    BOOL insertSucceed = lastCount == newCount - 1;
    XCTAssertTrue(insertSucceed);
}

#pragma mark - trackTimer
- (void)testTrackTimerStart {
    __block NSDictionary *callBackProperties = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];

    [[SensorsAnalyticsSDK sharedInstance] trackEventCallback:^BOOL (NSString *_Nonnull eventName, NSMutableDictionary<NSString *, id> *_Nonnull properties) {
        if ([eventName isEqualToString:@"timerEvent"]) {
            callBackProperties = properties;
            
            [expectation fulfill];
        }
        return YES;
    }];
    [[SensorsAnalyticsSDK sharedInstance] trackTimerStart:@"timerEvent"];
    sleep(1);
    [[SensorsAnalyticsSDK sharedInstance] trackTimerEnd:@"timerEvent"];


    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        BOOL isContainsDuration = [callBackProperties.allKeys containsObject:@"event_duration"];
        XCTAssertTrue(isContainsDuration);
    }];
}

- (void)testTrackTimerPause {
    __block float event_duration = 2.0;
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
    [[SensorsAnalyticsSDK sharedInstance] trackEventCallback:^BOOL (NSString *_Nonnull eventName, NSMutableDictionary<NSString *, id> *_Nonnull properties) {
        if ([eventName isEqualToString:@"timerEvent"]) {
            event_duration = [properties[@"event_duration"] floatValue];
            
            [expectation fulfill];
        }
        return YES;
    }];
    [[SensorsAnalyticsSDK sharedInstance] trackTimerStart:@"timerEvent"];

    sleep(1);
    [[SensorsAnalyticsSDK sharedInstance] trackTimerPause:@"timerEvent"];
    sleep(1);

    [[SensorsAnalyticsSDK sharedInstance] trackTimerEnd:@"timerEvent"];
    
    //如果计时器成功被暂停，则事件时长 event_duration = 1 秒（不考虑多线程和其他操作延时）
    // 如果计时器暂停失败，则事件时长 event_duration = 2 秒（不考虑多线程和其他操作延时）
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertLessThanOrEqual(event_duration, 1.1);
    }];
}

- (void)testTrackTimerResume {
    __block float event_duration = 0;
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
    [[SensorsAnalyticsSDK sharedInstance] trackEventCallback:^BOOL (NSString *_Nonnull eventName, NSMutableDictionary<NSString *, id> *_Nonnull properties) {
        if ([eventName isEqualToString:@"timerEvent"]) {
            event_duration = [properties[@"event_duration"] floatValue];
            
            [expectation fulfill];
        }
        return YES;
    }];
    [[SensorsAnalyticsSDK sharedInstance] trackTimerStart:@"timerEvent"];

    sleep(1);
    [[SensorsAnalyticsSDK sharedInstance] trackTimerPause:@"timerEvent"];
    sleep(1);

    [[SensorsAnalyticsSDK sharedInstance] trackTimerResume:@"timerEvent"];
    sleep(1);

    [[SensorsAnalyticsSDK sharedInstance] trackTimerEnd:@"timerEvent"];

    //判断是否恢复成功，如果恢复事件计时失败，事件时长 event_duration 只保留暂停前的计时：1 秒（不考虑多线程和其他操作延时）
    //如果恢复计时器成功，事件时长 event_duration = 2（不考虑多线程和其他操作延时）；
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
         XCTAssertGreaterThanOrEqual(event_duration, 1.1);
    }];
}

@end
