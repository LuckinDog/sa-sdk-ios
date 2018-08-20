//
//  SADelegateProxy.m
//  SADemo
//
//  Created by 向作为 on 2018/8/8.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import "SADelegateProxy.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "SensorsAnalyticsSDK_priv.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"
@interface SATableViewDelegateProxy:SADelegateProxy<UITableViewDelegate>
@end
@implementation SATableViewDelegateProxy
- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SALog(@"\n%@\n%@\n",tableView,indexPath);
    [SensorsAnalyticsSDK.sharedInstance tableView:tableView didSelectRowAtIndexPath:indexPath];
    if ([self.target respondsToSelector:_cmd]) {
        [self.target tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}
@end
@interface SACollectionViewDelegateProxy:SADelegateProxy<UICollectionViewDelegate>
@end
@implementation SACollectionViewDelegateProxy
- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    SALog(@"\n%@\n%@\n",collectionView,indexPath);
    [SensorsAnalyticsSDK.sharedInstance collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    if ([self.target respondsToSelector:_cmd]) {
        [self.target collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}
@end
@interface SAUIWebViewDelegateProxy:SADelegateProxy<UIWebViewDelegate>
@end
@implementation SAUIWebViewDelegateProxy
- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    SALog(@"\n%@\n%@\n",webView,request);

    BOOL shouldLoad = [SensorsAnalyticsSDK.sharedInstance webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    if (shouldLoad == YES) {
        if ([self.target respondsToSelector:_cmd]) {
            return  [self.target webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
        }
    }
    return shouldLoad;
}

@end
@interface SAWKWebViewDelegateProxy:SADelegateProxy<WKNavigationDelegate>
@end
@implementation SAWKWebViewDelegateProxy
- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    SALog(@"\n%@\n%@\n",webView,navigationAction);
    BOOL isSensorsReq = NO;
    [SensorsAnalyticsSDK.sharedInstance webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler isSensorsReq:&isSensorsReq];
    if (isSensorsReq) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    if ([self.target respondsToSelector:_cmd]) {
        return [self.target webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    }
}
@end

@interface SAUITabBarDelegateProxy :SADelegateProxy<UITabBarDelegate>
@end
@implementation SAUITabBarDelegateProxy
- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    // called when a new view is selected by the user (but not programatically)
    SALog(@"\n%@\n%@\n",tabBar,item);
    [SensorsAnalyticsSDK.sharedInstance tabBar:tabBar didSelectItem:item];
    if ([self.target respondsToSelector:_cmd]) {
        [self.target tabBar:tabBar didSelectItem:item];
    }
}
@end

@interface SAUIControlDelegateProxy :SADelegateProxy
@end
@implementation SAUIControlDelegateProxy
- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}
-(void)onClickUIControl:(id)control{
    //do something for track
    if ([self.target isKindOfClass:UITabBar.class]) {
        return;
    }
//    [SensorsAnalyticsSDK.sharedInstance onClickUIControl:control];
    SALog(@"\n%@\n%@\n",self.target,control);
}
@end

@interface SAUIGestureRecognizerDelegateProxy :SADelegateProxy
@end
@implementation SAUIGestureRecognizerDelegateProxy
- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}
-(void)onGestureRecognizer:(UIGestureRecognizer *)gesture{
    //do something for track
    SALog(@"\n%@\n%@\n",self.target,gesture);
    [SensorsAnalyticsSDK.sharedInstance onGestureRecognizer:gesture];
}
-(void)dealloc {

}
@end

@implementation SADelegateProxy
+(instancetype)proxyWithTableView:(id)target {
    SATableViewDelegateProxy *delegateProxy = [[SATableViewDelegateProxy alloc]initWithObject:target];
    return delegateProxy;
}

+(instancetype)proxyWithCollectionView:(id)target {
    SACollectionViewDelegateProxy *delegateProxy = [[SACollectionViewDelegateProxy alloc]initWithObject:target];
    return delegateProxy;
}

+(instancetype)proxyWithUIWebView:(id)target {
    SAUIWebViewDelegateProxy *delegateProxy = [[SAUIWebViewDelegateProxy alloc]initWithObject:target];
    return delegateProxy;
}

+(instancetype)proxyWithWKWebView:(id)target {
    SAWKWebViewDelegateProxy *delegateProxy = [[SAWKWebViewDelegateProxy alloc]initWithObject:target];
    return delegateProxy;
}

+(instancetype)proxyWithTabBar:(id)target {
    SAUITabBarDelegateProxy *delegateProxy = [[SAUITabBarDelegateProxy alloc]initWithObject:target];
    return delegateProxy;
}

+(instancetype)proxyWithUIControl:(id)target {
    SAUIControlDelegateProxy *delegateProxy = [[SAUIControlDelegateProxy alloc]initWithObject:target];
    return delegateProxy;
}

+(instancetype)proxyWithUIGestureRecognizer:(id)target {
    SAUIGestureRecognizerDelegateProxy *delegateProxy = [[SAUIGestureRecognizerDelegateProxy alloc]initWithObject:target];
    return delegateProxy;
}

- (id)initWithObject:(id)object {
    self.target = object;
    return self;
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [self.target methodSignatureForSelector:selector];
}
- (void)forwardInvocation:(NSInvocation *)invocation {
   
}

-(bool)respondsToSelector:(SEL)aSelector{
    if (aSelector == @selector(tableView:didSelectRowAtIndexPath:)) {
        return YES;
    }
    if (aSelector == @selector(collectionView:didSelectItemAtIndexPath:)) {
        return YES;
    }
    if (aSelector ==@selector(tabBar:didSelectItem:)) {
        return YES;
    }
    return [self.target respondsToSelector:aSelector];
}

-(void)dealloc {
    self.target = nil;
}
@end


