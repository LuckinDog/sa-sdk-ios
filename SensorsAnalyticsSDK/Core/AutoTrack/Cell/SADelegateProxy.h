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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SADelegateProxy : NSProxy

/**
 委托代理中的方法

 @param delegate 代理：UITableViewDelegate、UICollectionViewDelegate 等
 @param selector 代理中的方法
 */
+ (void)proxyWithDelegate:(id)delegate selector:(SEL)selector;

@end

@interface SADelegateProxy (ThirdPart)

+ (BOOL)isRxDelegateProxyClass:(Class)cla;

@end

@interface SADelegateProxy (SubclassMethod) <UITableViewDelegate, UICollectionViewDelegate>

- (Class)sensorsdata_class;

@end

@interface SADelegateProxy (SubClassDealloc)

- (void)addOperationWhenDealloc:(void(^)(void))block;

@end

NS_ASSUME_NONNULL_END
