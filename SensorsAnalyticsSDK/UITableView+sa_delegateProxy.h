//
//  UITableView+sa_autoTrack.h
//  SADemo
//
//  Created by 向作为 on 2018/8/8.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WKWebView.h>

@class SADelegateProxy;
@interface NSObject (sa_delegateProxy)
@property (nonatomic,strong,setter=sa_setDelagateProxy:) SADelegateProxy *sa_delegateProxy;
@end

@interface UITableView (sa_delegateProxy)
@end

@interface UICollectionView (sa_delegateProxy)
@end

@interface UIWebView (sa_delegateProxy)
@end

@interface WKWebView (sa_delegateProxy)
@end

@interface UITabBar (sa_delegateProxy)
@end

@interface UIView (sa_delegateProxy)
@end
