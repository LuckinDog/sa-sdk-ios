//
//  NSObject+SensorsAnalyticsDelegateProxy.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/8/8.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import "NSObject+SensorsAnalyticsDelegateProxy.h"
#import <objc/runtime.h>
#import <objc/objc.h>
#import <objc/message.h>
#import "SADelegateProxy.h"
void sa_setDelegate(id obj ,SEL sel, id delegate){
    SEL swizzileSel = sel_getUid("sa_setDelegate:");
    SADelegateProxy *delegateProxy = nil;
    if (delegate != nil) {
        delegateProxy = [obj sensorsAnalyticsDelegateProxy];
        if (delegateProxy == nil) {
            if ([obj isKindOfClass:UITableView.class]) {
                delegateProxy = [SADelegateProxy proxyWithTableView:delegate];
            }else if ([obj isKindOfClass:UICollectionView.class]){
                delegateProxy = [SADelegateProxy proxyWithCollectionView:delegate];
            }else if ([obj isKindOfClass:UITabBar.class]){
                delegateProxy = [SADelegateProxy proxyWithTabBar:delegate];
            }
        }else {
            [(SADelegateProxy *)delegateProxy setTarget:delegate];
        }
    }
    [(NSObject *)obj setSensorsAnalyticsDelegateProxy:delegateProxy];
    ((void (*)(id, SEL,id))objc_msgSend)(obj,swizzileSel,delegateProxy);
}

@implementation NSObject (SensorsAnalyticsDelegateProxy)

-(void)setSensorsAnalyticsDelegateProxy:(SADelegateProxy *)SensorsAnalyticsDelegateProxy{
    objc_setAssociatedObject(self, @selector(setSensorsAnalyticsDelegateProxy:), SensorsAnalyticsDelegateProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(SADelegateProxy *)sensorsAnalyticsDelegateProxy{
    return objc_getAssociatedObject(self, @selector(setSensorsAnalyticsDelegateProxy:));
}

@end

@implementation UITableView (SensorsAnalyticsDelegateProxy)
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

@implementation UICollectionView (SensorsAnalyticsDelegateProxy)
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

@implementation UITabBar (SensorsAnalyticsDelegateProxy)
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
        [(NSObject *)obj setSensorsAnalyticsDelegateProxy:delegateProxy];
    }
    ((void (*)(id, SEL,id))objc_msgSend)(obj,swizzileSel,gesture);
}

@implementation UIView (SensorsAnalyticsDelegateProxy)
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
