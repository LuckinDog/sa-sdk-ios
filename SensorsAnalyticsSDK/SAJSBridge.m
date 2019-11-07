//
// SAJSBridge.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2019/10/28.
// Copyright © 2019 SensorsData. All rights reserved.
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

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0

#import "SAJSBridge.h"
#import "SALogger.h"
#import "SensorsAnalyticsSDK+Private.h"

@implementation SAJSBridge

//wkwebview 打通
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"sensorsdataNativeTracker"]) {
        if (![message.body isKindOfClass:NSString.class]) {
            SAError(@"Failed to analysis message frome JS SDK, jsonString: %@", message.body);
            return;
        }
        SensorsAnalyticsSDK *sharedInstanceSDK = [SensorsAnalyticsSDK sharedInstance];
        [sharedInstanceSDK trackFromH5WithEvent:message.body enableVerify:sharedInstanceSDK.enableVerifyWKWebViewProject];
    }
}
@end

#endif
