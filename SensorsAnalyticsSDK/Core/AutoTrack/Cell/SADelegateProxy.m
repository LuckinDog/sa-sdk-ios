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
 根据实例对象生成动态添加的子类的名称

 @param obj 实例对象
 @return 子类类名
 */
NSString *sensorsdata_generateDynamicClassName(id obj) {
    Class class = object_getClass(obj);
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

+ (void)proxyWithDelegate:(id)delegate {
    @try {
        [self hookDidSelectMethodWithDelegate:delegate];
    } @catch (NSException *exception) {
        return SALogError(@"%@", exception);
    }
}

+ (void)hookDidSelectMethodWithDelegate:(id)delegate {
    SEL tablViewSelector = @selector(tableView:didSelectRowAtIndexPath:);
    SEL collectionViewSelector = @selector(collectionView:didSelectItemAtIndexPath:);
    
    BOOL canResponseTableView = [delegate respondsToSelector:tablViewSelector];
    BOOL canResponseCollectionView = [delegate respondsToSelector:collectionViewSelector];
    
    // 代理对象未实现单元格选中方法, 则不处理
    if (!canResponseTableView && !canResponseCollectionView) {
        return;
    }
    
    // 代理对象的继承链中存在动态添加的类, 则不重复添加类
    if (sensorsdata_dynamicClassInInheritanceChain(delegate)) {
        return;
    }
    
    // 创建类
    Class dynamicClass = [SAClassHelper createClassWithObject:delegate className:sensorsdata_generateDynamicClassName(delegate)];
    if (!dynamicClass) {
        return;
    }
    
    Class proxyClass = self.class;
    
    // hook tableView 的单元格选中方法
    if (canResponseTableView) {
        [SAMethodHelper addInstanceMethodWithSelector:tablViewSelector fromClass:proxyClass toClass:dynamicClass];
    }
    // hook collectionView 的单元格选中方法
    if (canResponseCollectionView) {
        [SAMethodHelper addInstanceMethodWithSelector:collectionViewSelector fromClass:proxyClass toClass:dynamicClass];
    }
    
    // 重写 - (Class)class 方法，隐藏新添加的子类
    [SAMethodHelper addInstanceMethodWithDestinationSelector:@selector(class) sourceSelector:@selector(sensorsdata_class) fromClass:proxyClass toClass:dynamicClass];
    
    // 实例释放时, 释放动态添加的子类
    [SAMethodHelper addInstanceMethodWithSelector:@selector(addOperationWhenDealloc:) fromClass:proxyClass toClass:dynamicClass];
    
    // 使类生效
    [SAClassHelper effectiveClass:dynamicClass];
    
    // 替换代理对象所归属的类
    if ([SAClassHelper configObject:delegate toClass:dynamicClass]) {
        [delegate addOperationWhenDealloc:^{
            if (sensorsdata_isDynamicClass(dynamicClass)) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    // 释放类
                    [SAClassHelper deallocClass:dynamicClass];
                });
            }
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
