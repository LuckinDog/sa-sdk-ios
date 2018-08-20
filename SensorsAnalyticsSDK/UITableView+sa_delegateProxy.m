//
//  UITableView+sa_autoTrack.m
//  SADemo
//
//  Created by 向作为 on 2018/8/8.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import "UITableView+sa_delegateProxy.h"
#import <objc/runtime.h>
#import <objc/objc.h>
#import <objc/message.h>
#import "SADelegateProxy.h"
void sa_setDelegate(id obj ,SEL sel, id delegate){
    SEL swizzileSel = sel_getUid("sa_setDelegate:");
    if (delegate != nil) {
        SADelegateProxy *delegateProxy = nil;
        if ([obj isKindOfClass:UITableView.class]) {
            delegateProxy = [SADelegateProxy proxyWithTableView:delegate];
        }else if ([obj isKindOfClass:UICollectionView.class]){
            delegateProxy = [SADelegateProxy proxyWithCollectionView:delegate];
        }else if ([obj isKindOfClass:UIWebView.class]){
            delegateProxy = [SADelegateProxy proxyWithUIWebView:delegate];
        }else if ([obj isKindOfClass:WKWebView.class]){
            delegateProxy = [SADelegateProxy proxyWithWKWebView:delegate];
        }else if ([obj isKindOfClass:UITabBar.class]){
            delegateProxy = [SADelegateProxy proxyWithTabBar:delegate];
        }
        delegate = delegateProxy;
    }
    [(NSObject *)obj sa_setDelagateProxy:delegate];
    ((void (*)(id, SEL,id))objc_msgSend)(obj,swizzileSel,delegate);
}

@implementation NSObject (sa_delegateProxy)

-(void)sa_setDelagateProxy:(SADelegateProxy *)sa_delegateProxy{
    objc_setAssociatedObject(self, @selector(sa_setDelagateProxy:), sa_delegateProxy, OBJC_ASSOCIATION_RETAIN);
}
-(SADelegateProxy *)sa_delegateProxy{
    return objc_getAssociatedObject(self, @selector(sa_setDelagateProxy:));
}

@end

@implementation UITableView (sa_delegateProxy)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL origSel_ = sel_getUid("setDelegate:");
        SEL swizzileSel = sel_getUid("sa_setDelegate:");
        Method origMethod = class_getInstanceMethod(self, origSel_);
        const char* type = method_getTypeEncoding(origMethod);
        class_addMethod(self, swizzileSel, (IMP)sa_setDelegate, type);
        Method swizzleMethod = class_getInstanceMethod(self, swizzileSel);
        IMP origIMP = method_getImplementation(origMethod);
        IMP swizzleIMP = method_getImplementation(swizzleMethod);
        method_setImplementation(origMethod, swizzleIMP);
        method_setImplementation(swizzleMethod, origIMP);
    });
}

@end

@implementation UICollectionView (sa_delegateProxy)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL origSel_ = sel_getUid("setDelegate:");
        SEL swizzileSel = sel_getUid("sa_setDelegate:");
        Method origMethod = class_getInstanceMethod(self, origSel_);
        const char* type = method_getTypeEncoding(origMethod);
        class_addMethod(self, swizzileSel, (IMP)sa_setDelegate, type);
        Method swizzleMethod = class_getInstanceMethod(self, swizzileSel);
        IMP origIMP = method_getImplementation(origMethod);
        IMP swizzleIMP = method_getImplementation(swizzleMethod);
        method_setImplementation(origMethod, swizzleIMP);
        method_setImplementation(swizzleMethod, origIMP);
    });
}

@end

@implementation UIWebView (sa_delegateProxy)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL origSel_ = sel_getUid("setDelegate:");
        SEL swizzileSel = sel_getUid("sa_setDelegate:");
        Method origMethod = class_getInstanceMethod(self, origSel_);
        const char* type = method_getTypeEncoding(origMethod);
        class_addMethod(self, swizzileSel, (IMP)sa_setDelegate, type);
        Method swizzleMethod = class_getInstanceMethod(self, swizzileSel);
        IMP origIMP = method_getImplementation(origMethod);
        IMP swizzleIMP = method_getImplementation(swizzleMethod);
        method_setImplementation(origMethod, swizzleIMP);
        method_setImplementation(swizzleMethod, origIMP);
    });
}

@end

@implementation WKWebView (sa_delegateProxy)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL origSel_ = sel_getUid("setNavigationDelegate:");
        SEL swizzileSel = sel_getUid("sa_setDelegate:");
        Method origMethod = class_getInstanceMethod(self, origSel_);
        const char* type = method_getTypeEncoding(origMethod);
        class_addMethod(self, swizzileSel, (IMP)sa_setDelegate, type);
        Method swizzleMethod = class_getInstanceMethod(self, swizzileSel);
        IMP origIMP = method_getImplementation(origMethod);
        IMP swizzleIMP = method_getImplementation(swizzleMethod);
        method_setImplementation(origMethod, swizzleIMP);
        method_setImplementation(swizzleMethod, origIMP);
    });
}

@end

@implementation UITabBar (sa_delegateProxy)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL origSel_ = sel_getUid("setDelegate:");
        SEL swizzileSel = sel_getUid("sa_setDelegate:");
        Method origMethod = class_getInstanceMethod(self, origSel_);
        const char* type = method_getTypeEncoding(origMethod);
        class_addMethod(self, swizzileSel, (IMP)sa_setDelegate, type);
        Method swizzleMethod = class_getInstanceMethod(self, swizzileSel);
        IMP origIMP = method_getImplementation(origMethod);
        IMP swizzleIMP = method_getImplementation(swizzleMethod);
        method_setImplementation(origMethod, swizzleIMP);
        method_setImplementation(swizzleMethod, origIMP);
    });
}

@end

void sa_addGestureRecognizer(id obj ,SEL sel, UIGestureRecognizer *gesture){
    SEL swizzileSel = sel_getUid("sa_addGestureRecognizer:");
    SEL action_proxy = sel_getUid("onGestureRecognizer:");
    SADelegateProxy *delegateProxy = nil;
    if ([obj isKindOfClass:UIImageView.class] || [obj isKindOfClass:UILabel.class]) {
        delegateProxy =  [SADelegateProxy proxyWithUIGestureRecognizer:obj];
        [gesture addTarget:delegateProxy action:action_proxy];
        [(NSObject *)obj sa_setDelagateProxy:delegateProxy];
    }
   
    ((void (*)(id, SEL,id))objc_msgSend)(obj,swizzileSel,gesture);
}

@implementation UIView (sa_delegateProxy)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL origSel_ = sel_getUid("addGestureRecognizer:");
        SEL swizzileSel = sel_getUid("sa_addGestureRecognizer:");
        Method origMethod = class_getInstanceMethod(self, origSel_);
        const char* type = method_getTypeEncoding(origMethod);
        class_addMethod(self, swizzileSel, (IMP)sa_addGestureRecognizer, type);
        Method swizzleMethod = class_getInstanceMethod(self, swizzileSel);
        IMP origIMP = method_getImplementation(origMethod);
        IMP swizzleIMP = method_getImplementation(swizzleMethod);
        method_setImplementation(origMethod, swizzleIMP);
        method_setImplementation(swizzleMethod, origIMP);
    });
}

@end

