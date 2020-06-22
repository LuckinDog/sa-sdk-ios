//
// SAEventFlush.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/6/18.
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

#import "SAEventFlush.h"
#import "NSString+HashCode.h"
#import "SAGzipUtility.h"
#import "SensorsAnalyticsSDK.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SANetwork.h"
#import "SALog.h"

@interface SAEventFlush ()

@end

@implementation SAEventFlush

- (instancetype)init {
    self = [super init];
    if (self) {

    }
    return self;
}

// 1. 先完成这一系列Json字符串的拼接
- (NSString *)buildFlushJSONStringWithEventRecords:(NSArray<SAEventRecord *> *)records {
    NSMutableArray *contents = [NSMutableArray arrayWithCapacity:records.count];
    for (SAEventRecord *record in records) {
        [contents addObject:record.content];
    }
    return [NSString stringWithFormat:@"[%@]", [contents componentsJoinedByString:@","]];
}

// 1. 先完成这一系列Json字符串的拼接
- (NSData *)buildBodyWithEventRecords:(NSArray<SAEventRecord *> *)records isEncrypted:(BOOL)isEncrypted {
    NSString *dataString = [self buildFlushJSONStringWithEventRecords:records];
    int gzip = 1; // gzip = 9 表示加密编码
    if (isEncrypted) {
        // 加密数据已{经做过 gzip 压缩和 base64 处理了，就不需要再处理。
        gzip = 9;
    } else {
        // 使用gzip进行压缩
        NSData *zippedData = [SAGzipUtility gzipData:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
        // base64
        dataString = [zippedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    }
    int hashCode = [dataString sensorsdata_hashCode];
    dataString = [dataString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    NSString *bodyString = [NSString stringWithFormat:@"crc=%d&gzip=%d&data_list=%@", hashCode, gzip, dataString];
    return [bodyString dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSURLRequest *)buildFlushRequestWithServerUrl:(NSString *)serverUrl eventRecords:(NSArray<SAEventRecord *> *)records isEncrypted:(BOOL)isEncrypted {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:serverUrl]];
    request.timeoutInterval = 30;
    request.HTTPMethod = @"POST";
    request.HTTPBody = [self buildBodyWithEventRecords:records isEncrypted:isEncrypted];
    // 普通事件请求，使用标准 UserAgent
    [request setValue:@"SensorsAnalytics iOS SDK" forHTTPHeaderField:@"User-Agent"];
    if ([SensorsAnalyticsSDK.sharedInstance debugMode] == SensorsAnalyticsDebugOnly) {
        [request setValue:@"true" forHTTPHeaderField:@"Dry-Run"];
    }

    return request;
}

- (void)flushEventRecords:(NSArray<SAEventRecord *> *)records isEncrypted:(BOOL)isEncrypted completion:(void (^)(BOOL success))completion {
    SensorsAnalyticsDebugMode debugMode = [SensorsAnalyticsSDK.sharedInstance debugMode];
    NSString *jsonString = [self buildFlushJSONStringWithEventRecords:records];

    SAURLSessionTaskCompletionHandler handler = ^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
            SALogError(@"%@ network failure: %@", self, error ? error : @"Unknown error");
            return completion(NO);
        }

        NSString *urlResponseContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSInteger statusCode = response.statusCode;
        NSString *messageDesc = nil;
        if (statusCode >= 200 && statusCode < 300) {
            messageDesc = @"\n【valid message】\n";
        } else {
            messageDesc = @"\n【invalid message】\n";
            if (statusCode >= 300 && debugMode != SensorsAnalyticsDebugOff) {
                NSString *errMsg = [NSString stringWithFormat:@"%@ flush failure with response '%@'.", self, urlResponseContent];
                [[SensorsAnalyticsSDK sharedInstance] showDebugModeWarning:errMsg withNoMoreButton:YES];
            }
        }
        // 1、开启 debug 模式，都删除；
        // 2、debugOff 模式下，只有 5xx & 404 & 403 不删，其余均删；
        BOOL successCode = (statusCode < 500 || statusCode >= 600) && statusCode != 404 && statusCode != 403;
        BOOL flushSuccess = debugMode != SensorsAnalyticsDebugOff || successCode;

        SALogDebug(@"==========================================================================");
        @try {
            NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
            SALogDebug(@"%@ %@: %@", self, messageDesc, dict);
        } @catch (NSException *exception) {
            SALogError(@"%@: %@", self, exception);
        }

        if (statusCode != 200) {
            SALogError(@"%@ ret_code: %ld, ret_content: %@", self, statusCode, urlResponseContent);
        }

        completion(flushSuccess);
    };

    NSString *serverUrl = SensorsAnalyticsSDK.sharedInstance.serverUrl;
    NSURLRequest *request = [self buildFlushRequestWithServerUrl:serverUrl eventRecords:records isEncrypted:isEncrypted];
    NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:handler];
    [task resume];
}

@end
