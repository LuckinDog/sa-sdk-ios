//
// SAModuleManager.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/8/14.
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

#import "SAModuleManager.h"

@interface SAModuleManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, id<SAModuleProtocol>> *modules;

@end

@implementation SAModuleManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SAModuleManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAModuleManager alloc] init];
    });
    return manager;
}

- (void)setEnable:(BOOL)enable forModule:(NSString *)moduleName {
    if (self.modules[moduleName]) {
        self.modules[moduleName].enable = enable;
    } else {
        Class<SAModuleProtocol> cla = NSClassFromString(moduleName);
        if ([cla conformsToProtocol:@protocol(SAModuleProtocol)]) {
            id<SAModuleProtocol> object = [[(Class)cla alloc] init];
            object.enable = enable;
            self.modules[moduleName] = object;
        }
    }
}

@end

#pragma mark -

@implementation SAModuleManager (Property)

- (NSDictionary *)properties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    for (NSString *key in self.modules) {
        id<SAPropertyModuleProtocol> object = (id<SAPropertyModuleProtocol>)self.modules[key];
        if ([object conformsToProtocol:@protocol(SAPropertyModuleProtocol)]) {
            [properties addEntriesFromDictionary:object.properties];
        }
    }
    return properties;
}

@end
