//
// SAThreadSafeDictionary.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/9/14.
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

#import "SAThreadSafeDictionary.h"

#define INIT(...) self = super.init; \
if (!self) return nil; \
__VA_ARGS__; \
if (!_dictionary) return nil; \
_lock = [[NSLock alloc] init]; \
return self;


#define LOCK(...) [_lock lock]; \
__VA_ARGS__; \
[_lock unlock];

@interface SAThreadSafeDictionary ()

@property (nonatomic, strong) NSMutableDictionary *dictionary;
@property (nonatomic, strong) NSLock *lock;

@end

@implementation SAThreadSafeDictionary

#pragma mark - init

- (instancetype)init {
    INIT(_dictionary = [[NSMutableDictionary alloc] init]);
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
    INIT(_dictionary = [[NSMutableDictionary alloc] initWithCapacity:numItems]);
}

- (instancetype)initWithObjects:(id  _Nonnull const [])objects forKeys:(id<NSCopying>  _Nonnull const [])keys count:(NSUInteger)cnt {
    INIT(_dictionary = [[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys count:cnt]);
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    INIT(_dictionary = [[NSMutableDictionary alloc] initWithCoder:coder]);
}

#pragma mark - method

- (NSUInteger)count {
    LOCK(NSUInteger c = _dictionary.count); return c;
}

- (id)objectForKey:(id)aKey {
    LOCK(id o = [_dictionary objectForKey:aKey]); return o;
}

- (NSEnumerator *)keyEnumerator {
    LOCK(NSEnumerator * e = [_dictionary keyEnumerator]); return e;
}

- (NSArray *)allKeys {
    LOCK(NSArray * a = [_dictionary allKeys]); return a;
}

- (NSArray *)allKeysForObject:(id)anObject {
    LOCK(NSArray * a = [_dictionary allKeysForObject:anObject]); return a;
}

- (NSArray *)allValues {
    LOCK(NSArray * a = [_dictionary allValues]); return a;
}

- (NSString *)description {
    LOCK(NSString * d = [_dictionary description]); return d;
}

- (NSString *)descriptionInStringsFileFormat {
    LOCK(NSString * d = [_dictionary descriptionInStringsFileFormat]); return d;
}

- (NSString *)descriptionWithLocale:(id)locale {
    LOCK(NSString * d = [_dictionary descriptionWithLocale:locale]); return d;
}

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level {
    LOCK(NSString * d = [_dictionary descriptionWithLocale:locale indent:level]); return d;
}

- (BOOL)isEqualToDictionary:(NSDictionary *)otherDictionary {
    if (otherDictionary == self) return YES;

    if ([otherDictionary isKindOfClass:SAThreadSafeDictionary.class]) {
        SAThreadSafeDictionary *other = (id)otherDictionary;
        BOOL isEqual;
        [self.lock lock];
        [other.lock lock];
        isEqual = [_dictionary isEqual:other.dictionary];
        [self.lock unlock];
        [other.lock unlock];
        return isEqual;
    }
    return NO;
}

- (NSEnumerator *)objectEnumerator {
    LOCK(NSEnumerator * e = [_dictionary objectEnumerator]); return e;
}

- (NSArray *)objectsForKeys:(NSArray *)keys notFoundMarker:(id)marker {
    LOCK(NSArray * a = [_dictionary objectsForKeys:keys notFoundMarker:marker]); return a;
}

- (NSArray *)keysSortedByValueUsingSelector:(SEL)comparator {
    LOCK(NSArray * a = [_dictionary keysSortedByValueUsingSelector:comparator]); return a;
}

- (void)getObjects:(id  _Nonnull __unsafe_unretained [])objects andKeys:(id  _Nonnull __unsafe_unretained [])keys {
    LOCK([_dictionary getObjects:objects andKeys:keys]);
}

- (id)objectForKeyedSubscript:(id)key {
    LOCK(id o = [_dictionary objectForKeyedSubscript:key]); return o;
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (NS_NOESCAPE ^)(id _Nonnull, id _Nonnull, BOOL * _Nonnull))block {
    LOCK([_dictionary enumerateKeysAndObjectsUsingBlock:block]);
}

- (void)enumerateKeysAndObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (NS_NOESCAPE ^)(id _Nonnull, id _Nonnull, BOOL * _Nonnull))block {
    LOCK([_dictionary enumerateKeysAndObjectsWithOptions:opts usingBlock:block]);
}

- (NSArray *)keysSortedByValueUsingComparator:(NSComparator NS_NOESCAPE)cmptr {
    LOCK(NSArray * a = [_dictionary keysSortedByValueUsingComparator:cmptr]); return a;
}

- (NSArray *)keysSortedByValueWithOptions:(NSSortOptions)opts usingComparator:(NSComparator NS_NOESCAPE)cmptr {
    LOCK(NSArray * a = [_dictionary keysSortedByValueWithOptions:opts usingComparator:cmptr]); return a;
}

- (NSSet *)keysOfEntriesPassingTest:(BOOL (NS_NOESCAPE ^)(id _Nonnull, id _Nonnull, BOOL * _Nonnull))predicate {
    LOCK(NSSet * a = [_dictionary keysOfEntriesPassingTest:predicate]); return a;
}

- (NSSet *)keysOfEntriesWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (NS_NOESCAPE ^)(id _Nonnull, id _Nonnull, BOOL * _Nonnull))predicate {
    LOCK(NSSet * a = [_dictionary keysOfEntriesWithOptions:opts passingTest:predicate]); return a;
}

#pragma mark - mutable

- (void)removeObjectForKey:(id)aKey {
    LOCK([_dictionary removeObjectForKey:aKey]);
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    LOCK([_dictionary setObject:anObject forKey:aKey]);
}

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary {
    LOCK([_dictionary addEntriesFromDictionary:otherDictionary]);
}

- (void)removeAllObjects {
    LOCK([_dictionary removeAllObjects]);
}

- (void)removeObjectsForKeys:(NSArray *)keyArray {
    LOCK([_dictionary removeObjectsForKeys:keyArray]);
}

- (void)setDictionary:(NSDictionary *)otherDictionary {
    LOCK([_dictionary setDictionary:otherDictionary]);
}

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
    LOCK([_dictionary setObject:obj forKeyedSubscript:key]);
}

#pragma mark - protocol

- (id)copyWithZone:(NSZone *)zone {
    return [self mutableCopyWithZone:zone];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    LOCK(id copiedDictionary = [[self.class allocWithZone:zone] initWithDictionary:_dictionary]);
    return copiedDictionary;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nullable [])buffer count:(NSUInteger)len {
    LOCK(NSUInteger count = [_dictionary countByEnumeratingWithState:state objects:buffer count:len]);
    return count;
}

- (BOOL)isEqual:(id)object {
    if (object == self) return YES;

    if ([object isKindOfClass:SAThreadSafeDictionary.class]) {
        SAThreadSafeDictionary *other = object;
        BOOL isEqual;
        [self.lock lock];
        [other.lock lock];
        isEqual = [_dictionary isEqual:other.dictionary];
        [self.lock unlock];
        [other.lock unlock];
        return isEqual;
    }
    return NO;
}

- (NSUInteger)hash {
    LOCK(NSUInteger hash = [_dictionary hash]);
    return hash;
}

@end
