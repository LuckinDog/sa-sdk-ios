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

+ (void)load {
    Class CAID = NSClassFromString(@"CAID");
    if (!CAID) {
        NSAssert(CAID, @"您未集成 CAID SDK，请按照集成文档正确集成后 CAID SDK 后调用 getCAIDAsyncly 接口获取 CAID 信息");
        return;
    }
    [CAID sa_swizzleMethod:NSSelectorFromString(@"getCAIDAsyncly:") withClass:SACAIDUtils.class withMethod:NSSelectorFromString(@"sensorsdata_getCAIDAsyncly:") error:nil];
}

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

#pragma mark - swizzled Method
- (void)sensorsdata_getCAIDAsyncly:(void(^)(id error, id caidStruct))callback {
    [self sensorsdata_getCAIDAsyncly:^(id _Nonnull error, id _Nonnull caidStruct) {
        SEL codeSel = NSSelectorFromString(@"code");
        if ([error respondsToSelector:codeSel]) {
            NSNumber *code = ((NSNumber * (*)(id, SEL))[error methodForSelector:codeSel])(error, codeSel);
            if (code.integerValue == 0) {
                NSMutableDictionary *caid = [NSMutableDictionary dictionary];
                SEL caidSel = NSSelectorFromString(@"caid");
                if ([caidStruct respondsToSelector:caidSel]) {
                    caid[@"caid"] = ((NSString * (*)(id, SEL))[caidStruct methodForSelector:caidSel])(caidStruct, caidSel);
                }
                SEL caidVersionSel = NSSelectorFromString(@"version");
                if ([caidStruct respondsToSelector:caidVersionSel]) {
                    caid[@"caid_version"] = ((NSString * (*)(id, SEL))[caidStruct methodForSelector:caidVersionSel])(caidStruct, caidVersionSel);
                }
                SEL lastVersionCAIDSel = NSSelectorFromString(@"lastVersionCAID");
                if ([caidStruct respondsToSelector:lastVersionCAIDSel]) {
                    caid[@"last_caid"] = ((NSString * (*)(id, SEL))[caidStruct methodForSelector:lastVersionCAIDSel])(caidStruct, lastVersionCAIDSel);
                }
                SEL lastVersionSel = NSSelectorFromString(@"lastVersion");
                if ([caidStruct respondsToSelector:lastVersionSel]) {
                    caid[@"last_caid_version"] = ((NSString * (*)(id, SEL))[caidStruct methodForSelector:lastVersionSel])(caidStruct, lastVersionSel);
                }
                // 客户每次调用 getCAIDAsyncly 方法成功后都会更新本地 CAID 信息
                [SAFileStore archiveWithFileName:kSACAIDCacheKey value:caid];
            }
        }
        callback(error, caidStruct);
    }];
}

@end
