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
    // 如果当前代理对象归属为 KVO 创建的类, 则无需新建子类
    if ([SADelegateProxy isKVOClass:realClass]) {
        // 在移除所有的 KVO 属性监听时, 系统会重置对象的 isa 指针为原有的类; 因此需要在移除监听时, 重新为代理对象设置新的子类, 来采集点击事件
        [SAMethodHelper addInstanceMethodWithSelector:@selector(removeObserver:forKeyPath:) fromClass:proxyClass toClass:realClass];
        [SAMethodHelper addInstanceMethodWithSelector:@selector(removeObserver:forKeyPath:context:) fromClass:proxyClass toClass:realClass];
        
        // 给 KVO 的类添加 cell 点击方法, 采集点击事件
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
    
    // 如果 tableView 和 collectionView 的点击事件都添加失败了, 则直接释放已创建的子类
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
        // 在对象释放时, 释放创建的子类
        [delegate sensorsdata_registerDeallocBlock:^{
            [SAClassHelper deallocClass:dynamicClass];
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
    // 获取到神策添加子类的父类
    Class dynamicClass = [SADelegateProxy sensorsClassInInheritanceChain:delegate];
    if (dynamicClass) {
        return class_getSuperclass(dynamicClass);
    }
    // 获取到 KVO 添加子类的父类
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
    // remove 前代理对象是否归属于 KVO 创建的类
    BOOL oldClassIsKVO = [SADelegateProxy isKVOClass:[SAClassHelper realClassWithObject:self]];
    [super removeObserver:observer forKeyPath:keyPath];
    // remove 后代理对象是否归属于 KVO 创建的类
    BOOL newClassIsKVO = [SADelegateProxy isKVOClass:[SAClassHelper realClassWithObject:self]];
    
    // 有多个属性监听时, 在最后一个监听被移除后, 对象的 isa 发生变化, 需要重新为代理对象添加子类
    if (oldClassIsKVO && !newClassIsKVO) {
        [SADelegateProxy proxyWithDelegate:self];
    }
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context {
    // remove 前代理对象是否归属于 KVO 创建的类
    BOOL oldClassIsKVO = [SADelegateProxy isKVOClass:[SAClassHelper realClassWithObject:self]];
    [super removeObserver:observer forKeyPath:keyPath context:context];
    // remove 后代理对象是否归属于 KVO 创建的类
    BOOL newClassIsKVO = [SADelegateProxy isKVOClass:[SAClassHelper realClassWithObject:self]];
    
    // 有多个属性监听时, 在最后一个监听被移除后, 对象的 isa 发生变化, 需要重新为代理对象添加子类
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
