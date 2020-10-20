//
//  UIScrollView+SensorsData.m
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

#import "UIScrollView+SensorsData.h"
#import "SADelegateProxy.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "SensorsAnalyticsSDK.h"
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK+Private.h"

void sensorsdata_setDelegate(id obj, SEL sel, id delegate) {
    // 获取 sensorsdata_setDelegate: 的方法名
    SEL swizzileSel = sel_getUid("sensorsdata_setDelegate:");
    // 调用 sensorsdata_setDelegate: 方法，由于之前已经交换，所以这里调用的是开发者自己实现的 setDelegate: 方法
    ((void (*)(id, SEL, id))objc_msgSend)(obj, swizzileSel, delegate);
    if (delegate == nil) {
        return;
    }
    // 判断是否忽略 $AppClick 事件采集
    if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
        return;
    }

    // 获取相应点击事件的方法（UITableView、UICollectionView）
    SEL selector = NULL;
    if ([obj isKindOfClass:[UITableView class]]) {
        selector = @selector(tableView:didSelectRowAtIndexPath:);
    } else if ([obj isKindOfClass:[UICollectionView class]]) {
        selector = @selector(collectionView:didSelectItemAtIndexPath:);
    }
    // 使用委托类去 hook 点击事件方法
    [SADelegateProxy proxyWithDelegate:delegate selector:selector];
}

void sensorsdata_swizzleSetDelegateMethod(Class _Nonnull cls) {
    // 获取原始方法
    SEL originalSel = sel_getUid("setDelegate:");
    // 获取 swizzle 的方法
    SEL swizzileSel = sel_getUid("sensorsdata_setDelegate:");
    // 通过方法名获取原始实例方法的实现
    Method originalMethod = class_getInstanceMethod(cls, originalSel);
    // 获取原始方法的类型（参数及返回值的类型），也是 sensorsdata_setDelegate: 方法的类型
    const char * type = method_getTypeEncoding(originalMethod);
    // 在类中添加 sensorsdata_setDelegate: 方法
    class_addMethod(cls, swizzileSel, (IMP)sensorsdata_setDelegate, type);
    // 在添加之后，获取改方法
    Method swizzleMethod = class_getInstanceMethod(cls, swizzileSel);
    // 获取 swizzle 方法的实现，即 sensorsdata_setDelegate: 方法
    IMP swizzleIMP = method_getImplementation(swizzleMethod);
    // 将 sensorsdata_setDelegate: 方法的实现设置给 setDelegate: 方法
    IMP originalIMP = method_setImplementation(originalMethod, swizzleIMP);
    // 将之前 sensorsdata_setDelegate: 方法的实现设置给 setDelegate: 方法
    method_setImplementation(swizzleMethod, originalIMP);
}

@implementation UITableView (SensorsData)

#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UITABLEVIEW

- (void)sensorsdata_setDelegate:(id <UITableViewDelegate>)delegate {
    [SADelegateProxy cancelProxyWithDelegate:self.delegate];
    [self sensorsdata_setDelegate:delegate];

    if (delegate == nil) {
        return;
    }
    // 判断是否忽略 $AppClick 事件采集
    if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
        return;
    }

    // 获取相应点击事件的方法
    SEL selector = @selector(tableView:didSelectRowAtIndexPath:);
    // 使用委托类去 hook 点击事件方法
    [SADelegateProxy proxyWithDelegate:delegate selector:selector];
}

#endif

@end


@implementation UICollectionView (SensorsData)

#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UICOLLECTIONVIEW

- (void)sensorsdata_setDelegate:(id <UICollectionViewDelegate>)delegate {
    [SADelegateProxy cancelProxyWithDelegate:self.delegate];
    [self sensorsdata_setDelegate:delegate];

    if (delegate == nil) {
        return;
    }
    // 判断是否忽略 $AppClick 事件采集
    if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
        return;
    }

    // 获取相应点击事件的方法
    SEL selector = @selector(collectionView:didSelectItemAtIndexPath:);
    // 使用委托类去 hook 点击事件方法
    [SADelegateProxy proxyWithDelegate:delegate selector:selector];
}
#endif

@end
