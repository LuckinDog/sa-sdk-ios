//
//  SensorsAnalyticsNetworkTests.m
//  SensorsAnalyticsTests
//
//  Created by MC on 2019/3/12.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SensorsAnalyticsNetwork.h"

@interface SensorsAnalyticsNetworkTests : XCTestCase
@property (nonatomic, strong) SensorsAnalyticsNetwork *network;
@end

@implementation SensorsAnalyticsNetworkTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSURL *url = [NSURL URLWithString:@"https://test.kbyte.cn:4106/"];
    _network = [[SensorsAnalyticsNetwork alloc] initWithServerURL:url];
    
    // 默认支持 DER 格式的证书
    NSString *cerPath = [[NSBundle bundleForClass:SensorsAnalyticsNetworkTests.class] pathForResource:@"cert" ofType:@"der"];//自签名证书
    NSData *data = [NSData dataWithContentsOfFile:cerPath];
    _network.certificateData = data;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    XCTestExpectation *exp = [self expectationWithDescription:@"这里可以是操作出错的原因描述。。。"];
    [self.network flushEvents:@[] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        XCTAssert(error == nil, @"xxixi");
        NSLog(@"%@", string);
        
        [exp fulfill];
    }];
    
    //设置延迟多少秒后，如果没有满足测试条件就报错
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
