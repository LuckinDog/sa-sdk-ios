//
// NSObject+SARelease.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2020/11/5.
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

#import "NSObject+SARelease.h"
#import <objc/runtime.h>

@interface SADelegateProxyParasite : NSObject

@property (nonatomic, copy) void(^deallocBlock)(void);

@end

@implementation SADelegateProxyParasite

- (void)dealloc {
    if (self.deallocBlock) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.deallocBlock();
        });
    }
}

@end

static void *const kSADelegateProxyParasiteName = (void *)&kSADelegateProxyParasiteName;

@interface NSObject (SARelease)

@property (nonatomic, strong) SADelegateProxyParasite *sensorsdata_parasite;

@end

@implementation NSObject (SARelease)

- (SADelegateProxyParasite *)sensorsdata_parasite {
    return objc_getAssociatedObject(self, kSADelegateProxyParasiteName);
}

- (void)setSensorsdata_parasite:(SADelegateProxyParasite *)parasite {
    objc_setAssociatedObject(self, kSADelegateProxyParasiteName, parasite, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)sensorsdata_registerDeallocBlock:(void (^)(void))deallocBlock {
    if (!self.sensorsdata_parasite) {
        self.sensorsdata_parasite = [[SADelegateProxyParasite alloc] init];
        self.sensorsdata_parasite.deallocBlock = deallocBlock;
    }
}

@end
