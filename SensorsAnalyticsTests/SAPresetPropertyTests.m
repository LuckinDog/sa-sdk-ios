//
// SAPresetPropertyTests.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2020/5/15.
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

#import <XCTest/XCTest.h>
#import "SAPresetProperty.h"
#import "SAConstants+Private.h"

@interface SAPresetPropertyTests : XCTestCase

@property (nonatomic, strong) SAPresetProperty *presetProperty;
@property (nonatomic, strong) dispatch_queue_t readWriteQueue;

@end

@implementation SAPresetPropertyTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    NSString *label = [NSString stringWithFormat:@"sensorsdata.readWriteQueue.%p", self];
    _readWriteQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
    _presetProperty = [[SAPresetProperty alloc] initWithQueue:_readWriteQueue];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    
    _presetProperty = nil;
}

- (void)testAutomaticProperties {
    NSDictionary *automaticProperties = _presetProperty.automaticProperties;
    
    XCTAssertTrue(automaticProperties.count > 0);
}

- (void)testAppVersion {
    NSString *appVersion = _presetProperty.appVersion;
    XCTAssertTrue(!appVersion || [appVersion isEqualToString:_presetProperty.automaticProperties[SA_EVENT_COMMON_PROPERTY_APP_VERSION]]);
}

- (void)testLib {
    NSString *lib = _presetProperty.lib;
    XCTAssertTrue([lib isEqualToString:_presetProperty.automaticProperties[SA_EVENT_COMMON_PROPERTY_LIB]]);
}

- (void)testLibVersion {
    NSString *libVersion = _presetProperty.libVersion;
    XCTAssertTrue([libVersion isEqualToString:_presetProperty.automaticProperties[SA_EVENT_COMMON_PROPERTY_LIB_VERSION]]);
}

- (void)testCurrentPresetProperties {
    NSDictionary *currentPresetProperties = [_presetProperty currentPresetProperties];
    
    // 时区偏移
    NSInteger hourOffsetGMT = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:[NSDate date]] / 60;
    NSNumber *timeZoneOfffset = currentPresetProperties[SA_EVENT_COMMON_PROPERTY_TIMEZONE_OFFSET];
    XCTAssertTrue([timeZoneOfffset isEqualToNumber:@(hourOffsetGMT)]);
    
    // app_id
    NSString *bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *appId = currentPresetProperties[SA_EVENT_COMMON_PROPERTY_APP_ID];
    XCTAssertTrue([bundleIdentifier isEqualToString:appId]);
}

@end
