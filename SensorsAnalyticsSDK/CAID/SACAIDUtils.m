//
// SACAIDUtils.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/3/4.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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

#import "SACAIDUtils.h"
#import "SASwizzle.h"
#import "SAFileStore.h"
#import "SALog.h"

static NSString *const kSACAIDCacheKey = @"com.sensorsdata.caid.cache";
static NSDictionary *caid;

@implementation SACAIDUtils

+ (NSDictionary *)CAIDInfo {
    Class CAID = NSClassFromString(@"CAID");
    if (!CAID) {
        SALogError(@"您未集成 CAID SDK，请按照集成文档正确集成 CAID SDK 后调用 getCAIDAsyncly 接口获取 CAID 信息");
        return nil;
    }
    if (!caid) {
        caid = [SAFileStore unarchiveWithFileName:kSACAIDCacheKey];
    }
    if (!caid) {
        SALogError(@"未获取到缓存的 CAID 信息，请检查是否正确集成 CAID SDK，并调用 getCAIDAsyncly 接口获取 CAID 信息");
        return nil;
    }
    return caid;
}

@end

@implementation NSObject (CAID)

+ (void)load {
    Class CAID = NSClassFromString(@"CAID");
    if (!CAID) {
        NSAssert(CAID, @"您未集成 CAID SDK，请按照集成文档正确集成后 CAID SDK 后调用 getCAIDAsyncly 接口获取 CAID 信息");
        return;
    }
    [CAID sa_swizzleMethod:NSSelectorFromString(@"getCAIDAsyncly:") withMethod:NSSelectorFromString(@"sensorsdata_getCAIDAsyncly:") error:nil];
}

- (void)sensorsdata_getCAIDAsyncly:(void(^)(id error, id caidStruct))callback {
    [self sensorsdata_getCAIDAsyncly:^(id _Nonnull error, id _Nonnull caidStruct) {
        if ([error respondsToSelector:NSSelectorFromString(@"code")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            NSInteger code = [[error performSelector:NSSelectorFromString(@"code")] integerValue];
            if (code == 0) {
                NSMutableDictionary *caid = [NSMutableDictionary dictionary];
                if ([caidStruct respondsToSelector:NSSelectorFromString(@"caid")]) {
                    caid[@"caid"] = [caidStruct performSelector:NSSelectorFromString(@"caid")];
                }
                if ([caidStruct respondsToSelector:NSSelectorFromString(@"version")]) {
                    caid[@"caid_version"] = [caidStruct performSelector:NSSelectorFromString(@"version")];
                }
                if ([caidStruct respondsToSelector:NSSelectorFromString(@"lastVersionCAID")]) {
                    caid[@"last_caid"] = [caidStruct performSelector:NSSelectorFromString(@"lastVersionCAID")];
                }
                if ([caidStruct respondsToSelector:NSSelectorFromString(@"lastVersion")]) {
                    caid[@"last_caid_version"] = [caidStruct performSelector:NSSelectorFromString(@"lastVersion")];
                }
                // 客户每次调用 getCAIDAsyncly 方法成功都会更新本地 CAID 信息
                [SAFileStore archiveWithFileName:kSACAIDCacheKey value:caid];
            }
#pragma clang diagnostic pop
        }
        callback(error, caidStruct);
    }];
}

@end
