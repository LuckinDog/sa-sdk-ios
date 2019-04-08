//
//  SAConfigOptions.m
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2019/4/8.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
//

#import "SAConfigOptions.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SensorsAnalyticsSDK.h"
#import "SensorsAnalyticsExceptionHandler.h"

@interface SAConfigOptions()

@end

@implementation SAConfigOptions

- (instancetype)initWithServerURL:(NSString *)serverURL launchOptions:(NSDictionary *)launchOptions {
    self = [super init];
    if (self) {
        _serverURL = serverURL;
        _launchOptions = launchOptions;
    }
    return self;
}

@end
