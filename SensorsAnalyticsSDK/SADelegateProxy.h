//
//  SADelegateProxy.h
//  SADemo
//
//  Created by 向作为 on 2018/8/8.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SADelegateProxy : NSProxy
@property(nonatomic,weak)id target;
+(instancetype)proxyWithTableView:(id)target;
+(instancetype)proxyWithCollectionView:(id)target;
+(instancetype)proxyWithUIWebView:(id)target;
+(instancetype)proxyWithWKWebView:(id)target;
+(instancetype)proxyWithTabBar:(id)target;
+(instancetype)proxyWithUIGestureRecognizer:(id)target;//UILabel，UIImageView
@end
