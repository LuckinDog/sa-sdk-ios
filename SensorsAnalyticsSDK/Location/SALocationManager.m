//
//  SALocationManager.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/5/7.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <UIKit/UIKit.h>
#import "SALocationManager.h"
#import "SALocationManager+SAConfig.h"
#import "SALog.h"

static NSString * const SAEventPresetPropertyLatitude = @"$latitude";
static NSString * const SAEventPresetPropertyLongitude = @"$longitude";

@interface SALocationManager() <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isUpdatingLocation;

@property (nonatomic, assign) BOOL isEnable;

@end

@implementation SALocationManager

- (instancetype)init {
    if (self = [super init]) {
        //默认设置设置精度为 100 ,也就是 100 米定位一次 ；准确性 kCLLocationAccuracyHundredMeters
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _locationManager.distanceFilter = 100.0;

        _isUpdatingLocation = NO;

        _coordinate = kCLLocationCoordinate2DInvalid;

        [self setupListeners];
    }
    return self;
}

#pragma mark - SALocationManagerProtocol

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SALocationManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SALocationManager alloc] init];
    });
    return manager;
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (enable) {
        [self startUpdatingLocation];
    } else {
        [self stopUpdatingLocation];
    }
}

- (NSDictionary *)properties {
    if (!CLLocationCoordinate2DIsValid(self.coordinate)) {
        return nil;
    }
    NSInteger latitude = self.coordinate.latitude * pow(10, 6);
    NSInteger longitude = self.coordinate.longitude * pow(10, 6);
    return @{SAEventPresetPropertyLatitude: @(latitude), SAEventPresetPropertyLongitude: @(longitude)};
}

#pragma mark - Listener

- (void)setupListeners {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (!self.disableSDK && self.isEnable) {
        [self startUpdatingLocation];
    } else {
        [self stopUpdatingLocation];
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self stopUpdatingLocation];
}

#pragma mark - Public

- (void)startUpdatingLocation {
    @try {
        //判断当前设备定位服务是否打开
        if (![CLLocationManager locationServicesEnabled]) {
            SALogWarn(@"设备尚未打开定位服务");
            return;
        }
        if (@available(iOS 8.0, *)) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        if (self.isUpdatingLocation == NO) {
            [self.locationManager startUpdatingLocation];
            self.isUpdatingLocation = YES;
        }
    }@catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)stopUpdatingLocation {
    @try {
        if (self.isUpdatingLocation) {
            [self.locationManager stopUpdatingLocation];
            self.isUpdatingLocation = NO;
        }
    }@catch (NSException *e) {
       SALogError(@"%@ error: %@", self, e);
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations API_AVAILABLE(ios(6.0), macos(10.9)) {
    self.coordinate = locations.lastObject.coordinate;
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    SALogError(@"enableTrackGPSLocation error：%@", error);
}

@end
