//
// SAScriptMessageHandler.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/3/18.
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

#import "SAScriptMessageHandler.h"
#import "SALogger.h"
#import "SensorsAnalyticsSDK+Private.h"

NSString * const SAScriptMessageHandlerMessageName = @"sensorsdataNativeTracker";

@interface SAScriptMessageHandler ()

@end

@implementation SAScriptMessageHandler

#pragma mark - Life Cycle

+ (instancetype)sharedInstance {
    static SAScriptMessageHandler *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SAScriptMessageHandler alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - Delegate

// Invoked when a script message is received from a webpage
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:SAScriptMessageHandlerMessageName]) {
        SAError(@"Message name is %@, not equal 'sensorsdataNativeTracker' from JS SDK", message.name);
        return;
    }
    
    if (![message.body isKindOfClass:[NSString class]]) {
        SAError(@"Message body is %@, not kind of 'NSString' from JS SDK", message.body);
        return;
    }
    
    @try {
        NSString *body = message.body;
        NSData *messageData = [body dataUsingEncoding:NSUTF8StringEncoding];
        if (!messageData) {
            return;
        }
        NSDictionary *messageDic = [NSJSONSerialization JSONObjectWithData:messageData options:NSJSONReadingMutableContainers error:nil];
        
        NSString *callType = messageDic[@"callType"];
        if ([callType isEqualToString:@"app_h5_track"]) {
            // H5 发送事件
            NSDictionary *trackMessageDic = messageDic[@"data"];
            if (!trackMessageDic) {
                return;
            }
            NSData *trackMessageData = [NSJSONSerialization dataWithJSONObject:trackMessageDic options:0 error:nil];
            NSString *trackMessageString = [[NSString alloc] initWithData:trackMessageData encoding:NSUTF8StringEncoding];
            [[SensorsAnalyticsSDK sharedInstance] trackFromH5WithEvent:trackMessageString];
        }
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

@end
