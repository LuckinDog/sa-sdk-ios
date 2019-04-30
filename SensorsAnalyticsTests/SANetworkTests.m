//
//  SANetworkTests.m
//  SANetworkTests
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
#import "SASecurityPolicy.h"
#import "SANetwork.h"
#import "SANetwork+URLUtils.h"

@interface SANetworkTests : XCTestCase
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) SANetwork *network;
@end

@implementation SANetworkTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _url = [NSURL URLWithString:@"https://sdk-test.datasink.sensorsdata.cn/sa?project=zhangminchao&token=95c73ae661f85aa0"];
    _network = [[SANetwork alloc] initWithServerURL:_url];
}

- (void)tearDown {
    _url = nil;
    _network = nil;
}

#pragma mark - URL Method
- (void)testGetHostWithURL {
    NSString *host = [SANetwork hostWithURL:_url];
    XCTAssertEqualObjects(host, @"sdk-test.datasink.sensorsdata.cn");
}

- (void)testGetHostWithNilURL {
    NSString *host = [SANetwork hostWithURL:nil];
    XCTAssertNil(host);
}

- (void)testGetHostWithURLString {
    NSString *host = [SANetwork hostWithURLString:@"https://www.google.com"];
    XCTAssertEqualObjects(host, @"www.google.com");
}

- (void)testGetHostWithMalformedURLString {
    NSString *host = [SANetwork hostWithURLString:@"google.com"];
    XCTAssertNil(host);
}

- (void)testGetQueryItemsWithURL {
    NSDictionary *items = [SANetwork queryItemsWithURL:_url];
    BOOL isEqual = [items isEqualToDictionary:@{@"project": @"zhangminchao", @"token": @"95c73ae661f85aa0"}];
    XCTAssertTrue(isEqual);
}

- (void)testGetQueryItemsWithNilURL {
    NSDictionary *items = [SANetwork queryItemsWithURL:nil];
    XCTAssertNil(items);
}

- (void)testGetQueryItemsWithURLString {
    NSDictionary *items = [SANetwork queryItemsWithURLString:@"https://sdk-test.datasink.sensorsdata.cn/sa?project=zhangminchao&token=95c73ae661f85aa0"];
    BOOL isEqual = [items isEqualToDictionary:@{@"project": @"zhangminchao", @"token": @"95c73ae661f85aa0"}];
    XCTAssertTrue(isEqual);
}

- (void)testGetQueryItemsWithNilURLString {
    NSDictionary *items = [SANetwork queryItemsWithURLString:nil];
    XCTAssertNil(items);
}

#pragma mark - Server URL
- (void)testDebugOffServerURL {
    XCTAssertEqual(self.network.serverURL, self.url);
}

- (void)testDebugOnlyServerURL {
    self.network.debugMode = SensorsAnalyticsDebugOnly;
    XCTAssertTrue([self.network.serverURL.lastPathComponent isEqualToString:@"debug"]);
}

- (void)testDebugAndTrackServerURL {
    self.network.debugMode = SensorsAnalyticsDebugAndTrack;
    XCTAssertTrue([self.network.serverURL.lastPathComponent isEqualToString:@"debug"]);
}


#pragma mark - Certificate
// 测试项目中有两个证书。ca.der.cer DER 格式的证书；ca.cer1 为 CER 格式的过期原始证书，若修改后缀为 cer，会崩溃；ca.outdate.cer 为过期证书
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
    BOOL success = [self.network flushEvents:@[@"{\"distinct_id\":\"1231456789\"}"]];
    XCTAssertTrue(success, @"Error");
}

#pragma mark - Request
- (NSArray<NSString *> *)createEventStringWithTime:(NSInteger)time {
    NSMutableArray *strings = [NSMutableArray arrayWithCapacity:50];
    for (NSInteger i = 0; i < 50; i ++) {
        NSInteger sss = time - (50 - i) * 1000 - arc4random()%1000;
        [strings addObject:[NSString stringWithFormat:@"{\"time\":%ld,\"_track_id\":%@,\"event\":\"$AppStart\",\"_flush_time\":%ld,\"distinct_id\":\"newId\",\"properties\":{\"$os_version\":\"12.1\",\"$device_id\":\"7460058E-2468-47C0-9E07-5C6BBADC1676\",\"AAA\":\"7460058E-2468-47C0-9E07-5C6BBADC1676\",\"$os\":\"iOS\",\"$screen_height\":896,\"$is_first_day\":false,\"$lib\":\"iOS\",\"$model\":\"x86_64\",\"$network_type\":\"WIFI\",\"$screen_width\":414,\"$app_version\":\"1.3\",\"$manufacturer\":\"Apple\",\"$wifi\":true,\"$lib_version\":\"1.10.23\",\"$is_first_time\":false,\"$resume_from_background\":false},\"type\":\"track\",\"lib\":{\"$lib_version\":\"1.10.23\",\"$lib\":\"iOS\",\"$lib_method\":\"autoTrack\",\"$app_version\":\"1.3\"}}", sss, @(arc4random()),sss]];
    }
    return strings;
}

- (void)testFlushEvents {
    XCTestExpectation *expect = [self expectationWithDescription:@"请求超时timeout!"];
    expect.expectedFulfillmentCount = 2;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        BOOL success1 = [self.network flushEvents:[self createEventStringWithTime:[NSDate date].timeIntervalSince1970 * 1000]];
        BOOL success2 = [self.network flushEvents:[self createEventStringWithTime:[NSDate date].timeIntervalSince1970 * 1000 - 70000]];
        XCTAssertTrue(success1 && success2, @"Error");
        
        [expect fulfill];
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        BOOL success1 = [self.network flushEvents:[self createEventStringWithTime:[NSDate date].timeIntervalSince1970 * 1000 - 70000]];
        BOOL success2 = [self.network flushEvents:[self createEventStringWithTime:[NSDate date].timeIntervalSince1970 * 1000]];
        XCTAssertTrue(success1 && success2, @"Error");
        
        [expect fulfill];
    });
    
    [self waitForExpectationsWithTimeout:45 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

- (void)testDebugModeCallback {
    XCTestExpectation *expect = [self expectationWithDescription:@"请求超时timeout!"];
    
    NSURLSessionTask *task = [self.network debugModeCallbackWithDistinctId:@"1234567890qwe" params:@{@"key": @"value"}];
    NSURL *url = task.currentRequest.URL;
    XCTAssertTrue([url.absoluteString rangeOfString:@"key=value"].location != NSNotFound);
    XCTAssertTrue([url.absoluteString rangeOfString:self.network.serverURL.host].location != NSNotFound);
    
    // 请求超时时间为 30s
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (task.state == NSURLSessionTaskStateRunning) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                XCTAssertNil(task.error);
                [expect fulfill];
            });
            return;
        }
        XCTAssertNil(task.error);
        [expect fulfill];
    });
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

- (void)testFunctionalManagermentConfig {
    NSString *version = @"1.2.qqq0";
    
    XCTestExpectation *expect = [self expectationWithDescription:@"请求超时timeout!"];
    NSURLSessionTask *task = [self.network functionalManagermentConfigWithRemoteConfigURL:nil version:version completion:^(BOOL success, NSDictionary<NSString *,id> * _Nonnull config) {
        XCTAssertTrue(success);
        [expect fulfill];
    }];
    NSURL *url = task.currentRequest.URL;
    NSString *string = [NSString stringWithFormat:@"v=%@", version];
    XCTAssertTrue([url.absoluteString rangeOfString:string].location != NSNotFound);
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
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
