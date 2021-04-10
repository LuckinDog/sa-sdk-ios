//
// SASuperPropertyManager.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/10.
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

#import "SASuperPropertyManager.h"
#import "SAFileStore.h"

@interface SASuperPropertyManager ()

@property (atomic, strong) NSDictionary *superProperties;

@end

@implementation SASuperPropertyManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [self unarchiveSuperProperties];
    }
    return self;
}

#pragma mark - SASuperPropertyModuleProtocol

- (void)registerSuperProperties:(NSDictionary *)propertyDict {
    [self unregisterSameLetterSuperProperties:propertyDict];
    // 注意这里的顺序，发生冲突时是以propertyDict为准，所以它是后加入的
    NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self.superProperties];
    [tmp addEntriesFromDictionary:propertyDict];
    self.superProperties = [NSDictionary dictionaryWithDictionary:tmp];
    [self archiveSuperProperties];
}

- (void)unregisterSuperProperty:(NSString *)property {
    NSMutableDictionary *superProperties = [NSMutableDictionary dictionaryWithDictionary:self.superProperties];
    if (property) {
        [superProperties removeObjectForKey:property];
    }
    self.superProperties = [NSDictionary dictionaryWithDictionary:superProperties];
    [self archiveSuperProperties];
}

- (NSDictionary *)currentSuperProperties {
    return [self.superProperties copy];
}

- (void)clearSuperProperties {
    self.superProperties = @{};
    [self archiveSuperProperties];
}

/// 注销仅大小写不同的 SuperProperties
/// @param propertyDict 公共属性
- (void)unregisterSameLetterSuperProperties:(NSDictionary *)propertyDict {
    NSArray *allNewKeys = [propertyDict.allKeys copy];
    //如果包含仅大小写不同的 key ,unregisterSuperProperty
    NSArray *superPropertyAllKeys = [self.superProperties.allKeys copy];
    NSMutableArray *unregisterPropertyKeys = [NSMutableArray array];
    for (NSString *newKey in allNewKeys) {
        [superPropertyAllKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *usedKey = (NSString *)obj;
            if ([usedKey caseInsensitiveCompare:newKey] == NSOrderedSame) { // 存在不区分大小写相同 key
                [unregisterPropertyKeys addObject:usedKey];
            }
        }];
    }
    if (unregisterPropertyKeys.count > 0) {
        [self removeDuplicateSuperProperties:unregisterPropertyKeys];
    }
}

#pragma mark - private

/// 移除公共属性
/// @param properties 待移除 key 的集合
- (void)removeDuplicateSuperProperties:(NSArray<NSString *> *)properties {
    NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self.superProperties];
    [tmp removeObjectsForKeys:properties];
    self.superProperties = [NSDictionary dictionaryWithDictionary:tmp];
}

#pragma mark - 缓存

- (void)unarchiveSuperProperties {
    NSDictionary *archivedSuperProperties = (NSDictionary *)[SAFileStore unarchiveWithFileName:@"super_properties"];
    _superProperties = archivedSuperProperties ? [archivedSuperProperties copy] : [NSDictionary dictionary];
}

- (void)archiveSuperProperties {
    [SAFileStore archiveWithFileName:@"super_properties" value:self.superProperties];
}

@end
