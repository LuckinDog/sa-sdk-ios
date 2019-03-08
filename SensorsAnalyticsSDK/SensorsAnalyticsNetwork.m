//
//  SensorsAnalyticsNetwork.m
//  SensorsAnalyticsSDK
//
//  Created by MC on 2019/3/8.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
//

#import "SensorsAnalyticsNetwork.h"

@interface SensorsAnalyticsNetwork ()

@property (nonatomic, strong) NSURL *serverURL;

+ (NSURLSession *)sharedURLSession;

@end

@implementation SensorsAnalyticsNetwork

+ (NSURLSession *)sharedURLSession {
    static NSURLSession *urlSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.timeoutIntervalForRequest = 30.0;
        urlSession = [NSURLSession sessionWithConfiguration:sessionConfig];
    });
    return urlSession;
}

- (void)flushEvents:(NSArray<NSString *> *)events {
    
}

@end
