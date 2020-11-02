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
#import "SAMethodHelper.h"
#import "SALog.h"
#import "SAAutoTrackUtils.h"
#import "SAAutoTrackProperty.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import <objc/runtime.h>
#import <objc/message.h>

typedef void (*SensorsDidSelectImplementation)(id, SEL, UIScrollView *, NSIndexPath *);

/// Delegate 的类前缀
static NSString *const kSADelegatePrefix = @"__CN.SENSORSDATA";
static NSString *const kSAClassSeparatedChar = @".";
static long subClassIndex = 0;

/**
 判断一个类是否有神策动态添加的类型

 @param class 当前类
 @return 是否有特殊前缀
 */
BOOL sensorsdata_isDynamicClass(Class _Nullable class) {
    return [NSStringFromClass(class) hasPrefix:kSADelegatePrefix];
}

/**
 从对象的 class 继承链中获取动态添加的类

 @param object 实例对象
 @return 动态添加的类; 继承链中不存在动态添加的类时, 返回 nil
 */
Class _Nullable sensorsdata_dynamicClassInInheritanceChain(id _Nullable object) {
    Class class = object_getClass(object);
    while (class) {
        if (sensorsdata_isDynamicClass(class)) {
            return class;
        }
        class = class_getSuperclass(class);
    }
    return nil;
}

/**
 根据原始类生成动态添加的子类的名称

 @param class 原始类
 @return 待添加的子类类名
 */
NSString *sensorsdata_generateDynamicClassName(Class class) {
    if (sensorsdata_isDynamicClass(class)) return NSStringFromClass(class);
    return [NSString stringWithFormat:@"%@%@%@%@", kSADelegatePrefix, @(subClassIndex++), kSAClassSeparatedChar, NSStringFromClass(class)];
}

/**
 获取 obj 的原始 Class

 @param obj 实例对象
 @return 原始类
 */
Class _Nullable sensorsdata_originalClass(id _Nullable obj) {
    Class cla = object_getClass(obj);
    if (!sensorsdata_isDynamicClass(cla)) return cla;
    NSString *className = [NSStringFromClass(cla) substringFromIndex:kSADelegatePrefix.length];
    NSString *prefix = [[className componentsSeparatedByString:kSAClassSeparatedChar].firstObject stringByAppendingString:kSAClassSeparatedChar];
    className = [className substringFromIndex:prefix.length];
    return objc_getClass([className UTF8String]);
}

@implementation SADelegateProxy

+ (void)proxyWithDelegate:(id)delegate selector:(SEL)selector {
    if (![delegate respondsToSelector:selector]) {
        return;
    }

    @try {
        [self createSubclassWithObject:delegate selector:selector];
    } @catch (NSException *exception) {
        return SALogError(@"%@", exception);
    }
}

/**
 isa swizzle
 给 object 创建一个新的子类，并设置其 isa 指针为新的子类。
 并且将 Delegate 对应的方法复制到新的子类中，这样就拦截了 object 中的 selector 方法

 @param object 需要创建子类的对象
 @param selector 需要 swizzle 的方法
 @return 新的子类
 */
+ (nullable Class)createSubclassWithObject:(id)object selector:(SEL)selector {
    
    if (sensorsdata_dynamicClassInInheritanceChain(object)) {
        return nil;
    }
    
    Class originalClass = object_getClass(object);
    NSString *newClassName = sensorsdata_generateDynamicClassName(originalClass);
    Class subclass = NSClassFromString(newClassName);
    if (!subclass) {
        // 注册一个新的子类，其父类为 originalClass
        subclass = objc_allocateClassPair(originalClass, newClassName.UTF8String, 0);

        Class proxyClass = [self class];
        // 向新的子类里添加新的实例方法
        [SAMethodHelper addInstanceMethodWithSelector:selector fromClass:proxyClass toClass:subclass];

        // 重写 - (void)class 方法，目的是在获取该类的类型时，隐藏新添加的子类
        [SAMethodHelper addInstanceMethodWithDestinationSelector:@selector(class) sourceSelector:@selector(sensorsdata_class) fromClass:proxyClass toClass:subclass];
        
        // 添加实例方法，目的是在实例释放时, 释放动态添加的子类
        [SAMethodHelper addInstanceMethodWithSelector:@selector(addOperationWhenDealloc:) fromClass:proxyClass toClass:subclass];

        // 子类和原始类的大小必须相同，不能有更多的 ivars 或者属性
        // 如果不同会导致设置新的子类时，会重新设置内存，导致重写了对象的 isa 指针
        if (class_getInstanceSize(originalClass) != class_getInstanceSize(subclass)) {
            SALogError(@"Cannot create subclass of Delegate, because the created subclass is not the same size. %@", NSStringFromClass(originalClass));
            NSAssert(NO, @"Classes must be the same size to swizzle isa");
            return nil;
        }

        objc_registerClassPair(subclass);
    }

    // 将 object 对象设置成新创建的子类对象
    if (object_setClass(object, subclass)) {
        [object addOperationWhenDealloc:^{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [SADelegateProxy deallocSubclass:subclass];
            });
        }];
        SALogDebug(@"Successfully created Delegate Proxy automatically.");
    }
    return subclass;
}

+ (void)deallocSubclass:(Class)class {
    if (!sensorsdata_isDynamicClass(class)) return;
    objc_disposeClassPair(class);
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
    return sensorsdata_originalClass(self);
}

+ (Class)handleClassWithDelegate:(id)delegate {
    Class dynamicClass = sensorsdata_dynamicClassInInheritanceChain(delegate);
    if (dynamicClass) {
        return class_getSuperclass(dynamicClass);
    }
    return object_getClass(delegate);
}

+ (void)invokeWithScrollView:(UIScrollView *)scrollView selector:(SEL)selector selectedAtIndexPath:(NSIndexPath *)indexPath {
    id delegate = scrollView.delegate;
    Class originalClass = [self handleClassWithDelegate:delegate];
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

#pragma mark - listening dealloc
@interface SADelegateProxyParasite : NSObject

@property (nonatomic, copy) void(^deallocBlock)(void);

@end

@implementation SADelegateProxyParasite

- (void)dealloc {
    !self.deallocBlock ?: self.deallocBlock();
}

@end

@implementation SADelegateProxy (SubClassDealloc)

- (void)addOperationWhenDealloc:(void(^)(void))block {
    @synchronized (self) {
        static NSString *kSAParasiteAssociatedKey = nil;
        NSMutableArray *parasiteList = objc_getAssociatedObject(self, &kSAParasiteAssociatedKey);
        if (!parasiteList) {
            parasiteList = [[NSMutableArray alloc] init];
            objc_setAssociatedObject(self, &kSAParasiteAssociatedKey, parasiteList, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        SADelegateProxyParasite *parasite = [[SADelegateProxyParasite alloc] init];
        parasite.deallocBlock = block;
        [parasiteList addObject: parasite];
    }
}

@end
