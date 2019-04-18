//
//  SAConfigOptions.m
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2019/4/8.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
//

#import "SAConfigOptions.h"
#import "SensorsAnalyticsSDK+Private.h"


@interface SAConfigOptions() 

@end

@implementation SAConfigOptions

- (instancetype)initWithServerURL:(NSString *)serverURL launchOptions:(NSDictionary *)launchOptions {
    
    self = [super init];
    if (self) {
        _serverURL = serverURL;
        _launchOptions = launchOptions;
        
        _autoTrackEventType = SensorsAnalyticsEventTypeNone;
        _flushInterval = 15 * 1000;
        _flushBulkSize = 100;
        _maxCacheSize = 10000;
        
        _minRequestHourInterval = 12;
        _maxRequestHourInterval = 24;
    }
    return self;
}

- (void)setFlushInterval:(NSInteger)flushInterval {
    _flushInterval = flushInterval >= 5000 ? flushInterval : 5000;
}

- (void)setFlushBulkSize:(NSInteger)flushBulkSize {
    _flushBulkSize = flushBulkSize >= 50 ? flushBulkSize : 50;
}

- (void)setMaxCacheSize:(NSInteger)maxCacheSize {
    //防止设置的值太小导致事件丢失
    _maxCacheSize = maxCacheSize >= 10000 ? maxCacheSize : 10000;
}

- (void)setMinRequestHourInterval:(NSInteger)minRequestHourInterval {
    if (minRequestHourInterval > 0) {
        _minRequestHourInterval = minRequestHourInterval;
    }
}

- (void)setMaxRequestHourInterval:(NSInteger)maxRequestHourInterval {
    if (maxRequestHourInterval > 0) {
        _maxRequestHourInterval = maxRequestHourInterval;
    }
}
@end
