//
//  UITableView+sa_autoTrack.m
//  SADemo
//
//  Created by ziven.mac on 2018/8/8.
//  Copyright © 2018年 ziven.mac. All rights reserved.
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

-(void)dealloc{
    
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

-(void)dealloc{
    
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

-(void)dealloc{
    
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

-(void)dealloc{
    
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

-(void)dealloc{
    
}
@end
//void sa_addTargetWithActionForControlEvents(id obj ,SEL sel, id target,SEL action, UIControlEvents events){
//    SEL swizzileSel = sel_getUid("sa_addTarget:action:forControlEvents:");
//    SEL action_proxy = sel_getUid("onClickUIControl:");
//    SADelegateProxy *delegateProxy = nil;
//    delegateProxy = [SADelegateProxy proxyWithUIControl:target];
//    [(NSObject *)obj sa_setDelagateProxy:delegateProxy];
//    ((void (*)(id, SEL,id,SEL,UIControlEvents))objc_msgSend)(obj,swizzileSel,target,action,events);
//    ((void (*)(id, SEL,id,SEL,UIControlEvents))objc_msgSend)(obj,swizzileSel,delegateProxy,action_proxy,events);
//}

//@implementation UIControl (sa_delegateProxy)
//+ (void)load {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        SEL origSel_ = sel_getUid("addTarget:action:forControlEvents:");
//        SEL swizzileSel = sel_getUid("sa_addTarget:action:forControlEvents:");
//        Method origMethod = class_getInstanceMethod(self, origSel_);
//        const char* type = method_getTypeEncoding(origMethod);
//        class_addMethod(self, swizzileSel, (IMP)sa_addTargetWithActionForControlEvents, type);
//        Method swizzleMethod = class_getInstanceMethod(self, swizzileSel);
//        IMP origIMP = method_getImplementation(origMethod);
//        IMP swizzleIMP = method_getImplementation(swizzleMethod);
//        method_setImplementation(origMethod, swizzleIMP);
//        method_setImplementation(swizzleMethod, origIMP);
//    });
//}
//
//-(void)dealloc{
//
//}
//
//@end

void sa_addGestureRecognizer(id obj ,SEL sel, UIGestureRecognizer *gesture){
    SEL swizzileSel = sel_getUid("sa_addGestureRecognizer:");
    SEL action_proxy = sel_getUid("onGestureRecognizer:");
    SADelegateProxy *delegateProxy = nil;
    if ([obj isKindOfClass:UIImageView.class] || [obj isKindOfClass:UILabel.class]) {
        delegateProxy =  [SADelegateProxy proxyWithUIGestureRecognizer:obj];
        [gesture addTarget:delegateProxy action:action_proxy];
        [(NSObject *)obj sa_setDelagateProxy:delegateProxy];
    }
   
#if (defined SENSORS_ANALYTICS_ENABLE_NO_PUBLICK_APIS)
    if ([obj isKindOfClass:NSClassFromString(@"_UIAlertControllerView")] || [obj isKindOfClass:NSClassFromString(@"_UIAlertControllerInterfaceActionGroupView")]) {
        delegateProxy =  [SADelegateProxy proxyWithUIGestureRecognizer:obj];
        [gesture addTarget:delegateProxy action:action_proxy];
        [(NSObject *)obj sa_setDelagateProxy:delegateProxy];
    }
#endif
    ((void (*)(id, SEL,id))objc_msgSend)(obj,swizzileSel,gesture);
}
@interface UIView (sa_delegateProxy)
@end
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

-(void)dealloc{
    
}

@end

