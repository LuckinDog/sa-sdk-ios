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
//测试 itemSet 接口，是否成功
- (void)testItemSet {
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
    
    dispatch_queue_t queue = dispatch_queue_create("sensorsData-Test", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        
        NSInteger lastCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
        [[SensorsAnalyticsSDK sharedInstance] itemSetWithType:@"itemSet0517" itemId:@"itemId0517" properties:@{@"itemSet":@"acsdfgvzscd"}];
        
        sleep(1);
        
        NSInteger newCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
        BOOL insertSucceed = newCount == lastCount + 1;
        XCTAssertTrue(insertSucceed);
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

//测试 itemDelete 接口，是否成功
- (void)testItemDelete {
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
    
    dispatch_queue_t queue = dispatch_queue_create("sensorsData-Test", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        NSInteger lastCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
        [[SensorsAnalyticsSDK sharedInstance] itemDeleteWithType:@"itemSet0517" itemId:@"itemId0517"];
        
        sleep(1);
        
        NSInteger newCount = [SensorsAnalyticsSDK sharedInstance].messageQueue.count;
        BOOL insertSucceed = newCount == lastCount + 1;
        XCTAssertTrue(insertSucceed);
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

#pragma mark - trackTimer
///测试是否开启事件计时
- (void)testShouldTrackTimerStart {
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
    
    dispatch_queue_t queue = dispatch_queue_create("sensorsData-Test", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        
        [[SensorsAnalyticsSDK sharedInstance] trackEventCallback:^BOOL (NSString *_Nonnull eventName, NSMutableDictionary<NSString *, id> *_Nonnull properties) {
            if ([eventName isEqualToString:@"timerEvent"]) {
                
                NSDictionary *callBackProperties = properties;
                BOOL isContainsDuration = [callBackProperties.allKeys containsObject:@"event_duration"];
                XCTAssertTrue(isContainsDuration);
                
                [expectation fulfill];
            }
            return YES;
        }];
        [[SensorsAnalyticsSDK sharedInstance] trackTimerStart:@"timerEvent"];
        sleep(1);
        [[SensorsAnalyticsSDK sharedInstance] trackTimerEnd:@"timerEvent"];
        
    });
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
         XCTAssertNil(error);
    }];
}

/// 测试事件计时暂停
- (void)testTrackTimerPause {
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
    
    __block float event_duration = 2.0;
    dispatch_queue_t queue = dispatch_queue_create("sensorsData-Test", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        
        [[SensorsAnalyticsSDK sharedInstance] trackEventCallback:^BOOL (NSString *_Nonnull eventName, NSMutableDictionary<NSString *, id> *_Nonnull properties) {
            if ([eventName isEqualToString:@"timerEvent"]) {
                event_duration = [properties[@"event_duration"] floatValue];
                
                //如果计时器成功被暂停，则事件时长 event_duration = 1 秒（不考虑多线程和其他操作延时）
                // 如果计时器暂停失败，则事件时长 event_duration = 2 秒（不考虑多线程和其他操作延时）
                XCTAssertLessThanOrEqual(event_duration, 1.1);
                
                [expectation fulfill];
            }
            return YES;
        }];
        [[SensorsAnalyticsSDK sharedInstance] trackTimerStart:@"timerEvent"];
        
        sleep(1);
        [[SensorsAnalyticsSDK sharedInstance] trackTimerPause:@"timerEvent"];
        sleep(1);
        
        [[SensorsAnalyticsSDK sharedInstance] trackTimerEnd:@"timerEvent"];
        
    });
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

/// 测试事件计时暂停后恢复
- (void)testTrackTimerResume {
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
    
    dispatch_queue_t queue = dispatch_queue_create("sensorsData-Test", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        
        [[SensorsAnalyticsSDK sharedInstance] trackEventCallback:^BOOL (NSString *_Nonnull eventName, NSMutableDictionary<NSString *, id> *_Nonnull properties) {
            if ([eventName isEqualToString:@"timerEvent"]) {
               float event_duration = [properties[@"event_duration"] floatValue];
                
                //判断是否恢复成功，如果恢复事件计时失败，事件时长 event_duration 只保留暂停前的计时：1 秒（不考虑多线程和其他操作延时）
                //如果恢复计时器成功，事件时长 event_duration = 2（不考虑多线程和其他操作延时）；
                XCTAssertGreaterThanOrEqual(event_duration, 1.1);
                
                [expectation fulfill];
            }
            return YES;
        }];
        
        //开始计时
        [[SensorsAnalyticsSDK sharedInstance] trackTimerStart:@"timerEvent"];
        
        sleep(1);
        //暂停
        [[SensorsAnalyticsSDK sharedInstance] trackTimerPause:@"timerEvent"];
        sleep(1);
        
        //恢复
        [[SensorsAnalyticsSDK sharedInstance] trackTimerResume:@"timerEvent"];
        sleep(1);
        
        //事件计时结束
        [[SensorsAnalyticsSDK sharedInstance] trackTimerEnd:@"timerEvent"];
    });

    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

@end
