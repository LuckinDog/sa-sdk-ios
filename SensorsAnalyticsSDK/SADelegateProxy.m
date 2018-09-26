//
//  SADelegateProxy.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/8/8.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import "SADelegateProxy.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "SensorsAnalyticsSDK+Private.h"
#import "SensorsAnalyticsSDK.h"
@interface SATableViewDelegateProxy:SADelegateProxy<UITableViewDelegate>
@end
@implementation SATableViewDelegateProxy
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.target respondsToSelector:_cmd]) {
        [SensorsAnalyticsSDK.sharedInstance tableView:tableView didSelectRowAtIndexPath:indexPath];
        [self.target tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}
-(BOOL)respondsToSelector:(SEL)aSelector{
    if (aSelector == @selector(tableView:didSelectRowAtIndexPath:)) {
        return YES;
    }
    return NO;
}

@end
@interface SACollectionViewDelegateProxy:SADelegateProxy<UICollectionViewDelegate>
@end
@implementation SACollectionViewDelegateProxy
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if ([self.target respondsToSelector:_cmd]) {
        [SensorsAnalyticsSDK.sharedInstance collectionView:collectionView didSelectItemAtIndexPath:indexPath];
        [self.target collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}
-(BOOL)respondsToSelector:(SEL)aSelector{
    if (aSelector == @selector(collectionView:didSelectItemAtIndexPath:)) {
        return YES;
    }
    return NO;
}

@end

@interface SAUITabBarDelegateProxy :SADelegateProxy<UITabBarDelegate>
@end
@implementation SAUITabBarDelegateProxy

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    [[SensorsAnalyticsSDK sharedInstance] tabBar:tabBar didSelectItem:item];
    if ([self.target respondsToSelector:_cmd]) {
        [self.target tabBar:tabBar didSelectItem:item];
    }
}

-(BOOL)respondsToSelector:(SEL)aSelector{
    if (aSelector == @selector(tabBar:didSelectItem:)) {
        return YES;
    }
    return NO;
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
    [SensorsAnalyticsSDK.sharedInstance onGestureRecognizer:gesture];
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

+(instancetype)proxyWithTabBar:(id)target {
    SAUITabBarDelegateProxy *delegateProxy = [[SAUITabBarDelegateProxy alloc]initWithObject:target];
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
    [invocation invokeWithTarget:self.target];
}

-(void)dealloc {
    self.target = nil;
}
@end


