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
    NSURL *url = [NSURL URLWithString:@"https://test.kbyte.cn:4106/sa"];
    _network = [[SANetwork alloc] initWithServerURL:url];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testCustomCertificate {
    NSURL *url = [NSURL URLWithString:@"https://test.kbyte.cn:4106/sa"];
    SANetwork *network = [[SANetwork alloc] initWithServerURL:url];
    
    SASecurityPolicy *securityPolicy = [SASecurityPolicy policyWithPinningMode:SASSLPinningModeCertificate];
    securityPolicy.allowInvalidCertificates = YES;
    securityPolicy.validatesDomainName = NO;

    network.securityPolicy = securityPolicy;
    
    // 默认支持 DER 格式的证书
//    NSString *cerPath = [[NSBundle bundleForClass:SensorsAnalyticsNetworkTests.class] pathForResource:@"cert" ofType:@"der"];//自签名证书
//    NSData *data = [NSData dataWithContentsOfFile:cerPath];
//    network.certificateData = data;
    
    BOOL success = [network flushEvents:@[]];
    XCTAssertTrue(success, @"Error");
}

- (void)testHTTPSServerURL {
    NSURL *url = [NSURL URLWithString:@"https://sdk-test.datasink.sensorsdata.cn/sa?project=zhangminchao&token=95c73ae661f85aa0"];
    SANetwork *network = [[SANetwork alloc] initWithServerURL:url];    
    BOOL success = [network flushEvents:@[]];
    XCTAssertTrue(success, @"Error");
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
//    NSURL *url = [NSURL URLWithString:@"https://sdk-test.datasink.sensorsdata.cn/sa?project=zhangminchao&token=95c73ae661f85aa0"];
    NSURL *url = [NSURL URLWithString:@"http://sdk-test.datasink.sensorsdata.cn/sa?project=zhangminchao&token=95c73ae661f85aa0"];
    SANetwork *network = [[SANetwork alloc] initWithServerURL:url];
    
    // 默认支持 DER 格式的证书
//    NSString *cerPath = [[NSBundle bundleForClass:SensorsAnalyticsNetworkTests.class] pathForResource:@"cert" ofType:@"der"];//自签名证书
//    NSData *data = [NSData dataWithContentsOfFile:cerPath];
//    network.certificateData = data;
    
    BOOL success = [network flushEvents:@[]];
    XCTAssertTrue(success, @"Error");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
