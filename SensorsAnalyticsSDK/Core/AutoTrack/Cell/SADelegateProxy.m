//
//  SADelegateProxy.m
//  SensorsAnalyticsSDK
//
//  Created by 张敏超🍎 on 2019/6/19.
//  Copyright © 2019 SensorsData. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "SADelegateProxy.h"
#import "SAClassHelper.h"
#import "SAMethodHelper.h"
#import "NSObject+SARelease.h"
#import "SALog.h"
#import "SAAutoTrackUtils.h"
#import "SAAutoTrackProperty.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import <objc/runtime.h>
#import <objc/message.h>

typedef void (*SensorsDidSelectImplementation)(id, SEL, UIScrollView *, NSIndexPath *);

@implementation SADelegateProxy

+ (void)proxyWithDelegate:(id)delegate {
    @try {
        [SADelegateProxy hookDidSelectMethodWithDelegate:delegate];
    } @catch (NSException *exception) {
        return SALogError(@"%@", exception);
    }
}

+ (void)hookDidSelectMethodWithDelegate:(id)delegate {
    // 代理对象的继承链中存在动态添加的类, 则不重复添加类
    if ([SADelegateProxy sensorsClassInInheritanceChain:delegate]) {
        return;
    }
    
    SEL tablViewSelector = @selector(tableView:didSelectRowAtIndexPath:);
    SEL collectionViewSelector = @selector(collectionView:didSelectItemAtIndexPath:);
    
    BOOL canResponseTableView = [delegate respondsToSelector:tablViewSelector];
    BOOL canResponseCollectionView = [delegate respondsToSelector:collectionViewSelector];
    
    // 代理对象未实现单元格选中方法, 则不处理
    if (!canResponseTableView && !canResponseCollectionView) {
        return;
    }
    Class proxyClass = self.class;
    Class realClass = [SAClassHelper realClassWithObject:delegate];
    if ([SADelegateProxy isKVOClass:realClass]) {
        [SAMethodHelper addInstanceMethodWithSelector:@selector(removeObserver:forKeyPath:) fromClass:proxyClass toClass:realClass];
        [SAMethodHelper addInstanceMethodWithSelector:@selector(removeObserver:forKeyPath:context:) fromClass:proxyClass toClass:realClass];
        [SAMethodHelper addInstanceMethodWithSelector:tablViewSelector fromClass:proxyClass toClass:realClass];
        [SAMethodHelper addInstanceMethodWithSelector:collectionViewSelector fromClass:proxyClass toClass:realClass];
        return;
    }
    
    // 创建类
    NSString *dynamicClassName = [SADelegateProxy generateSensorsClassName:delegate];
    Class dynamicClass = [SAClassHelper createClassWithObject:delegate className:dynamicClassName];
    if (!dynamicClass) {
        return;
    }
    
    BOOL swizzleSuccess = NO;
    swizzleSuccess = [SAMethodHelper addInstanceMethodWithSelector:tablViewSelector fromClass:proxyClass toClass:dynamicClass];
    swizzleSuccess = [SAMethodHelper addInstanceMethodWithSelector:collectionViewSelector fromClass:proxyClass toClass:dynamicClass] || swizzleSuccess;
    if (!swizzleSuccess) {
        [SAClassHelper deallocClass:dynamicClass];
        return;
    }
    
    // 重写 - (Class)class 方法，隐藏新添加的子类
    [SAMethodHelper addInstanceMethodWithDestinationSelector:@selector(class) sourceSelector:@selector(sensorsdata_class) fromClass:proxyClass toClass:dynamicClass];
    
    // 使类生效
    [SAClassHelper effectiveClass:dynamicClass];
    
    // 替换代理对象所归属的类
    if ([SAClassHelper configObject:delegate toClass:dynamicClass]) {
        [delegate sensorsdata_registerDeallocBlock:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // 释放类
                [SAClassHelper deallocClass:dynamicClass];
            });
        }];
    }
}

@end

#pragma mark - RxSwift

@implementation SADelegateProxy (ThirdPart)

+ (BOOL)isRxDelegateProxyClass:(Class)cla {
    NSString *className = NSStringFromClass(cla);
    // 判断类名是否为 RxCocoa 中的代理类名
    if ([className hasSuffix:@"RxCollectionViewDelegateProxy"] || [className hasSuffix:@"RxTableViewDelegateProxy"]) {
        return YES;
    }
    return NO;
}

@end

#pragma mark - UITableViewDelegate & UICollectionViewDelegate

@implementation SADelegateProxy (SubclassMethod)

/// Overridden instance class method
- (Class)sensorsdata_class {
    return [SADelegateProxy originalClass:self];
}

+ (Class)handleClassWithDelegate:(id)delegate {
    Class dynamicClass = [SADelegateProxy sensorsClassInInheritanceChain:delegate];
    if (dynamicClass) {
        return class_getSuperclass(dynamicClass);
    }
    Class currentClass = [SAClassHelper realClassWithObject:delegate];
    if ([SADelegateProxy isKVOClass:currentClass]) {
        return class_getSuperclass(currentClass);
    }
    return object_getClass(delegate);
}

+ (void)invokeWithScrollView:(UIScrollView *)scrollView selector:(SEL)selector selectedAtIndexPath:(NSIndexPath *)indexPath {
    id delegate = scrollView.delegate;
    Class originalClass = [SADelegateProxy handleClassWithDelegate:delegate];
    IMP originalImplementation = [SAMethodHelper implementationOfMethodSelector:selector fromClass:originalClass];
    if (originalImplementation) {
        ((SensorsDidSelectImplementation)originalImplementation)(delegate, selector, scrollView, indexPath);
    } else if ([SADelegateProxy isRxDelegateProxyClass:originalClass]) {
        ((SensorsDidSelectImplementation)_objc_msgForward)(delegate, selector, scrollView, indexPath);
    }

    NSMutableDictionary *properties = [SAAutoTrackUtils propertiesWithAutoTrackObject:(UIScrollView<SAAutoTrackViewProperty> *)scrollView didSelectedAtIndexPath:indexPath];
    if (!properties) {
        return;
    }
    NSDictionary *dic = [SAAutoTrackUtils propertiesWithAutoTrackDelegate:scrollView didSelectedAtIndexPath:indexPath];
    [properties addEntriesFromDictionary:dic];

    [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SEL methodSelector = @selector(tableView:didSelectRowAtIndexPath:);
    [SADelegateProxy invokeWithScrollView:tableView selector:methodSelector selectedAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    SEL methodSelector = @selector(collectionView:didSelectItemAtIndexPath:);
    [SADelegateProxy invokeWithScrollView:collectionView selector:methodSelector selectedAtIndexPath:indexPath];
}

@end

#pragma mark - KVO
@implementation SADelegateProxy (KVO)

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    BOOL oldClassIsKVO = [SADelegateProxy isKVOClass:[SAClassHelper realClassWithObject:self]];
    [super removeObserver:observer forKeyPath:keyPath];
    BOOL newClassIsKVO = [SADelegateProxy isKVOClass:[SAClassHelper realClassWithObject:self]];
    if (oldClassIsKVO && !newClassIsKVO) {
        [SADelegateProxy proxyWithDelegate:self];
    }
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context {
    BOOL oldClassIsKVO = [SADelegateProxy isKVOClass:[SAClassHelper realClassWithObject:self]];
    [super removeObserver:observer forKeyPath:keyPath context:context];
    BOOL newClassIsKVO = [SADelegateProxy isKVOClass:[SAClassHelper realClassWithObject:self]];
    if (oldClassIsKVO && !newClassIsKVO) {
        [SADelegateProxy proxyWithDelegate:self];
    }
}

@end

#pragma mark - Utils
/// Delegate 的类前缀
static NSString *const kSADelegatePrefix = @"__CN.SENSORSDATA";
static NSString *const kSAClassSeparatedChar = @".";
static long subClassIndex = 0;

@implementation SADelegateProxy (Utils)

/// 是不是 KVO 创建的类
/// @param cls 类
+ (BOOL)isKVOClass:(Class _Nullable)cls {
    return [NSStringFromClass(cls) hasPrefix:@"NSKVONotifying_"];
}

/// 是不是神策创建的类
/// @param cls 类
+ (BOOL)isSensorsClass:(Class _Nullable)cls {
    return [NSStringFromClass(cls) hasPrefix:kSADelegatePrefix];
}

/// 获取神策创建类的父类
/// @param obj 实例对象
+ (Class _Nullable)originalClass:(id _Nullable)obj {
    Class cla = object_getClass(obj);
    if (![SADelegateProxy isSensorsClass:cla]) return cla;
    NSString *className = [NSStringFromClass(cla) substringFromIndex:kSADelegatePrefix.length];
    NSString *prefix = [[className componentsSeparatedByString:kSAClassSeparatedChar].firstObject stringByAppendingString:kSAClassSeparatedChar];
    className = [className substringFromIndex:prefix.length];
    return objc_getClass([className UTF8String]);
}

/// 生成神策要创建类的类名
/// @param obj 实例对象
+ (NSString *)generateSensorsClassName:(id)obj {
    Class class = object_getClass(obj);
    if ([SADelegateProxy isSensorsClass:class]) return NSStringFromClass(class);
    return [NSString stringWithFormat:@"%@%@%@%@", kSADelegatePrefix, @(subClassIndex++), kSAClassSeparatedChar, NSStringFromClass(class)];
}

/// 实例对象的 class 继承链中是否包含神策添加的类
/// @param obj 实例对象
+ (Class _Nullable)sensorsClassInInheritanceChain:(id _Nullable)obj {
    Class class = object_getClass(obj);
    while (class) {
        if ([SADelegateProxy isSensorsClass:class]) {
            return class;
        }
        class = class_getSuperclass(class);
    }
    return nil;
}

@end
