//
//  SADelegateProxy.h
//  SADemo
//
//  Created by ziven.mac on 2018/8/8.
//  Copyright © 2018年 ziven.mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SADelegateProxy : NSProxy
@property(nonatomic,weak)id target;
+(instancetype)proxyWithTableView:(id)target;
+(instancetype)proxyWithCollectionView:(id)target;
+(instancetype)proxyWithUIWebView:(id)target;
+(instancetype)proxyWithWKWebView:(id)target;
+(instancetype)proxyWithTabBar:(id)target;
//+(instancetype)proxyWithUIControl:(id)target;
+(instancetype)proxyWithUIGestureRecognizer:(id)target;//仅支持UILabel，UIImageView
@end
