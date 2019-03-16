//
//  SensorsAnalyticsNetworkTests.m
//  SensorsAnalyticsTests
//
//  Created by MC on 2019/3/12.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SASecurityPolicy.h"
#import "SANetwork.h"

@interface SensorsAnalyticsNetworkTests : XCTestCase
@property (nonatomic, strong) SANetwork *network;
@end

@implementation SensorsAnalyticsNetworkTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testServerURL {
    NSURL *url = [NSURL URLWithString:@"https://sdk-test.datasink.sensorsdata.cn/sa?project=zhangminchao&token=95c73ae661f85aa0"];
    SANetwork *network = [[SANetwork alloc] initWithServerURL:url];
    XCTAssertEqual(network.serverURL, url);
    
    network.debugMode = SensorsAnalyticsDebugOnly;
    XCTAssertTrue([network.serverURL.lastPathComponent isEqualToString:@"debug"]);

    network.debugMode = SensorsAnalyticsDebugAndTrack;
    XCTAssertTrue([network.serverURL.lastPathComponent isEqualToString:@"debug"]);
}

#pragma mark - Certificate
- (void)testCustomCertificate {
    NSURL *url = [NSURL URLWithString:@"https://test.kbyte.cn:4106/sa"];
    SANetwork *network = [[SANetwork alloc] initWithServerURL:url];
    
    SASecurityPolicy *securityPolicy = [SASecurityPolicy policyWithPinningMode:SASSLPinningModeCertificate];
    securityPolicy.allowInvalidCertificates = YES;
    securityPolicy.validatesDomainName = NO;

    network.securityPolicy = securityPolicy;
    
    BOOL success = [network flushEvents:@[@"{\"distinct_id\":\"1231456789\"}"]];
    XCTAssertTrue(success, @"Error");
}

- (void)testHTTPSServerURL {
    NSURL *url = [NSURL URLWithString:@"https://sdk-test.datasink.sensorsdata.cn/sa?project=zhangminchao&token=95c73ae661f85aa0"];
    SANetwork *network = [[SANetwork alloc] initWithServerURL:url];    
    BOOL success = [network flushEvents:@[@"{\"distinct_id\":\"1231456789\"}"]];
    XCTAssertTrue(success, @"Error");
}

#pragma mark - Flush
- (NSArray<NSString *> *)createEventStringWithTime:(NSInteger)time {
    NSMutableArray *strings = [NSMutableArray arrayWithCapacity:50];
    for (NSInteger i = 0; i < 50; i ++) {
        NSInteger sss = time - (50 - i) * 1000 - arc4random()%1000;
        [strings addObject:[NSString stringWithFormat:@"{\"time\":%ld,\"_track_id\":%@,\"event\":\"$AppStart\",\"_flush_time\":%ld,\"distinct_id\":\"newId\",\"properties\":{\"$os_version\":\"12.1\",\"$device_id\":\"7460058E-2468-47C0-9E07-5C6BBADC1676\",\"AAA\":\"7460058E-2468-47C0-9E07-5C6BBADC1676\",\"$os\":\"iOS\",\"$screen_height\":896,\"$is_first_day\":false,\"$lib\":\"iOS\",\"$model\":\"x86_64\",\"$network_type\":\"WIFI\",\"$screen_width\":414,\"$app_version\":\"1.3\",\"$manufacturer\":\"Apple\",\"$wifi\":true,\"$lib_version\":\"1.10.23\",\"$is_first_time\":false,\"$resume_from_background\":false},\"type\":\"track\",\"lib\":{\"$lib_version\":\"1.10.23\",\"$lib\":\"iOS\",\"$lib_method\":\"autoTrack\",\"$app_version\":\"1.3\"}}", sss, @(arc4random()),sss]];
    }
    return strings;
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    NSURL *url = [NSURL URLWithString:@"https://sdk-test.datasink.sensorsdata.cn/sa?project=zhangminchao&token=95c73ae661f85aa0"];
//    NSURL *url = [NSURL URLWithString:@"http://sdk-test.datasink.sensorsdata.cn/sa?project=zhangminchao&token=95c73ae661f85aa0"];
    SANetwork *network = [[SANetwork alloc] initWithServerURL:url];
    
    //1: 创建XCTestExpectation对象
    XCTestExpectation *expect = [self expectationWithDescription:@"请求超时timeout!"];
    expect.expectedFulfillmentCount = 2;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        BOOL success1 = [network flushEvents:[self createEventStringWithTime:[NSDate date].timeIntervalSince1970 * 1000]];
        BOOL success2 = [network flushEvents:[self createEventStringWithTime:[NSDate date].timeIntervalSince1970 * 1000 - 70000]];
        XCTAssertTrue(success1 && success2, @"Error");
        
        [expect fulfill];
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        BOOL success1 = [network flushEvents:[self createEventStringWithTime:[NSDate date].timeIntervalSince1970 * 1000 - 70000]];
        BOOL success2 = [network flushEvents:[self createEventStringWithTime:[NSDate date].timeIntervalSince1970 * 1000]];
        XCTAssertTrue(success1 && success2, @"Error");
        
        [expect fulfill];
    });
    
    [self waitForExpectationsWithTimeout:45 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
