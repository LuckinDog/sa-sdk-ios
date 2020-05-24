//
// SAPresetProperty.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/5/12.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#include <sys/sysctl.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import "SAPresetProperty.h"
#import "SAConstants+Private.h"
#import "SAIdentifier.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SACommonUtility.h"
#import "SALog.h"
#import "SAFileStore.h"
#import "SADateFormatter.h"
#import "SADeviceOrientationManager.h"
#import "SALocationManager.h"
#import "SAValidator.h"

//中国运营商 mcc 标识
static NSString* const CARRIER_CHINA_MCC = @"460";

@interface SAPresetProperty ()

@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, copy) NSDictionary *automaticProperties;
@property (nonatomic, copy) NSString *firstDay;
@property (nonatomic, copy) NSString *libVersion;

@end

@implementation SAPresetProperty

#pragma mark - Life Cycle

- (instancetype)initWithQueue:(dispatch_queue_t)queue libVersion:(NSString *)libVersion {
    self = [super init];
    if (self) {
        self.queue = queue;
        self.libVersion = libVersion;
    }
    return self;
}

#pragma mark – Public Methods

- (void)unarchiveFirstDay {
    @try {
        dispatch_async(self.queue, ^{
            self.firstDay = [SAFileStore unarchiveWithFileName:@"first_day"];
            if (self.firstDay == nil) {
                NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@"yyyy-MM-dd"];
                self.firstDay = [dateFormatter stringFromDate:[NSDate date]];
                [SAFileStore archiveWithFileName:@"first_day" value:self.firstDay];
            }
        });
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
}

- (BOOL)isFirstDay {
    __block BOOL isFirstDay = NO;
    sensorsdata_dispatch_safe_sync(self.queue, ^{
        NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@"yyyy-MM-dd"];
        NSString *current = [dateFormatter stringFromDate:[NSDate date]];
        isFirstDay = [self.firstDay isEqualToString:current];
    });
    return isFirstDay;
}

- (NSDictionary *)currentPresetProperties {
    __block NSDictionary *presetProperties = nil;
    @try {
        sensorsdata_dispatch_safe_sync(self.queue, ^{
            NSString *networkType = [SACommonUtility currentNetworkStatus];
            
            NSMutableDictionary *automaticPropertiesMDic = [NSMutableDictionary dictionaryWithDictionary:self.automaticProperties];
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_NETWORK_TYPE] = networkType;
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_WIFI] = @([networkType isEqualToString:@"WIFI"]);
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_IS_FIRST_DAY] = @([self isFirstDay]);
            
            presetProperties = [NSDictionary dictionaryWithDictionary:automaticPropertiesMDic];
        });
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
    return presetProperties;
}

- (NSString *)appVersion {
    return self.automaticProperties[SA_EVENT_COMMON_PROPERTY_APP_VERSION];
}

- (NSString *)lib {
    return self.automaticProperties[SA_EVENT_COMMON_PROPERTY_LIB];
}

- (NSDictionary *)presetPropertiesOfTrackType:(BOOL)isLaunchedPassively
                            orientationConfig:(SADeviceOrientationConfig *)orientationConfig
                               locationConfig:(SAGPSLocationConfig *)locationConfig {
    
    NSMutableDictionary *presetPropertiesOfTrackType = [NSMutableDictionary dictionary];
    
    @try {
        sensorsdata_dispatch_safe_sync(self.queue, ^{
            // 是否首日访问
            presetPropertiesOfTrackType[SA_EVENT_COMMON_PROPERTY_IS_FIRST_DAY] = @([self isFirstDay]);
            
            // 是否被动启动
            if (isLaunchedPassively) {
                presetPropertiesOfTrackType[SA_EVENT_COMMON_OPTIONAL_PROPERTY_APP_STATE] = @"background";
            }
            
            // 采集设备方向
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
            if (orientationConfig.enableTrackScreenOrientation && [SAValidator isValidString:orientationConfig.deviceOrientation]) {
                presetPropertiesOfTrackType[SA_EVENT_COMMON_OPTIONAL_PROPERTY_SCREEN_ORIENTATION] = orientationConfig.deviceOrientation;
            }
#endif
            // 采集地理位置信息
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
            if (locationConfig.enableGPSLocation && CLLocationCoordinate2DIsValid(locationConfig.coordinate)) {
                NSInteger latitude = locationConfig.coordinate.latitude * pow(10, 6);
                NSInteger longitude = locationConfig.coordinate.longitude * pow(10, 6);
                presetPropertiesOfTrackType[SA_EVENT_COMMON_OPTIONAL_PROPERTY_LATITUDE] = @(latitude);
                presetPropertiesOfTrackType[SA_EVENT_COMMON_OPTIONAL_PROPERTY_LONGITUDE] = @(longitude);
            }
#endif
        });
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
    
    return [NSDictionary dictionaryWithDictionary:presetPropertiesOfTrackType];
}

#pragma mark – Private Methods

+ (NSString *)deviceModel {
    NSString *results = nil;
    @try {
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char answer[size];
        sysctlbyname("hw.machine", answer, &size, NULL, 0);
        results = @(answer);
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
    return results;
}

+ (NSString *)carrierName {
    NSString *carrierName = nil;
    @try {
        CTTelephonyNetworkInfo *telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = nil;
        
#ifdef __IPHONE_12_0
        if (@available(iOS 12.1, *)) {
            // 排序
            NSArray *carrierKeysArray = [telephonyInfo.serviceSubscriberCellularProviders.allKeys sortedArrayUsingSelector:@selector(compare:)];
            carrier = telephonyInfo.serviceSubscriberCellularProviders[carrierKeysArray.firstObject];
            if (!carrier.mobileNetworkCode) {
                carrier = telephonyInfo.serviceSubscriberCellularProviders[carrierKeysArray.lastObject];
            }
        }
#endif
        if (!carrier) {
            carrier = telephonyInfo.subscriberCellularProvider;
        }
        if (carrier != nil) {
            NSString *networkCode = [carrier mobileNetworkCode];
            NSString *countryCode = [carrier mobileCountryCode];
            
            //中国运营商
            if (countryCode && [countryCode isEqualToString:CARRIER_CHINA_MCC]) {
                if (networkCode) {
                    //中国移动
                    if ([networkCode isEqualToString:@"00"] || [networkCode isEqualToString:@"02"] || [networkCode isEqualToString:@"07"] || [networkCode isEqualToString:@"08"]) {
                        carrierName= @"中国移动";
                    }
                    //中国联通
                    if ([networkCode isEqualToString:@"01"] || [networkCode isEqualToString:@"06"] || [networkCode isEqualToString:@"09"]) {
                        carrierName= @"中国联通";
                    }
                    //中国电信
                    if ([networkCode isEqualToString:@"03"] || [networkCode isEqualToString:@"05"] || [networkCode isEqualToString:@"11"]) {
                        carrierName= @"中国电信";
                    }
                    //中国卫通
                    if ([networkCode isEqualToString:@"04"]) {
                        carrierName= @"中国卫通";
                    }
                    //中国铁通
                    if ([networkCode isEqualToString:@"20"]) {
                        carrierName= @"中国铁通";
                    }
                }
            } else if (countryCode && networkCode) { //国外运营商解析
                //加载当前 bundle
                NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[SensorsAnalyticsSDK class]] pathForResource:@"SensorsAnalyticsSDK" ofType:@"bundle"]];
                //文件路径
                NSString *jsonPath = [sensorsBundle pathForResource:@"sa_mcc_mnc_mini.json" ofType:nil];
                NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
                if (jsonData) {
                    NSDictionary *dicAllMcc =  [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
                    if (dicAllMcc) {
                        NSString *mccMncKey = [NSString stringWithFormat:@"%@%@", countryCode, networkCode];
                        carrierName = dicAllMcc[mccMncKey];
                    }
                }
            }
        }
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
    return carrierName;
}

#pragma mark – Getters and Setters

- (NSDictionary *)automaticProperties {
    __block NSDictionary *automaticProperties = nil;
    sensorsdata_dispatch_safe_sync(self.queue, ^{
        if (!_automaticProperties) {
            NSMutableDictionary *automaticPropertiesMDic = [NSMutableDictionary dictionary];
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_CARRIER] = [SAPresetProperty carrierName];
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_APP_VERSION] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_DEVICEID
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_DEVICE_ID] = [SAIdentifier uniqueHardwareId];
#endif
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_LIB] = @"iOS";
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_LIB_VERSION] = self.libVersion;
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_MANUFACTURER] = @"Apple";
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_OS] = @"iOS";
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_OS_VERSION] = [[UIDevice currentDevice] systemVersion];
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_MODEL] = [SAPresetProperty deviceModel];
            CGSize size = [UIScreen mainScreen].bounds.size;
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_SCREEN_HEIGHT] = @((NSInteger)size.height);
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_SCREEN_WIDTH] = @((NSInteger)size.width);
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_APP_ID] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
            // 计算时区偏移（保持和 JS 获取时区偏移的计算结果一致，这里首先获取分钟数，然后取反）
            NSInteger hourOffsetGMT = - ([[NSTimeZone systemTimeZone] secondsFromGMT] / 60);
            automaticPropertiesMDic[SA_EVENT_COMMON_PROPERTY_TIMEZONE_OFFSET] = @(hourOffsetGMT);
            
            _automaticProperties = [NSDictionary dictionaryWithDictionary:automaticPropertiesMDic];
        }
        automaticProperties = _automaticProperties;
    });
    return automaticProperties;
}

@end
