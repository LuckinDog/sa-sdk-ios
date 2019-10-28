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

#import "SAJSBridge.h"

@implementation SAJSBridge

//wkwebview 打通
-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"sensorsdataNativeTracker"]) {

        NSData *jsonData = [message.body dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        NSDictionary *messageDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];

        if (error || ![messageDic isKindOfClass:NSDictionary.class]) {
            // 解析失败，日志提示
            return;
        }

        // json 解析获取 JS SDK 发送的数据，iOS SDK 做打通处理
        NSLog(@"打通的测试数据 --- %@",message.body);

    }
}

@end
