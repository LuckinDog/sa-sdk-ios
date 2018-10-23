//
//  NSObject+SensorsAnalyticsDelegate.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/8/8.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//
#ifdef SENSORS_ANALYTICS_ENABLE_AUTOTRACT_DIDSELECTROW

#import "NSObject+SensorsAnalyticsDelegate.h"
#import <objc/runtime.h>
#import <objc/objc.h>
#import <objc/message.h>
#import "AutoTrackUtils.h"
#import "SensorsAnalyticsSDK.h"
static NSMutableArray *arrChachedClassForCollectionViewDelegate = nil;
static NSMutableArray *arrChachedClassForTableViewDelegate = nil;

@interface NSObject (SensorsAnalyticsDelegate)
+ (BOOL)addMethod:(Class)class sel:(SEL)sel method:(IMP)method;
+ (void)swapMethod:(Class)class origMethod:(SEL)origSelector newMethod:(SEL)newSelector;
+ (BOOL)hasMethod:(Class)class sel:(SEL)sel;
@end

void swizzle_didSelectRowAtIndexPath(id self, SEL _cmd, id tableView, id indexPath){
    SEL selector = NSSelectorFromString(@"swizzle_didSelectRowAtIndexPath");
    ((void(*)(id, SEL, id, id))objc_msgSend)(self, selector, tableView, indexPath);
    [AutoTrackUtils trackAppClickWithUITableView:tableView didSelectRowAtIndexPath:indexPath];
}

void swizzle_didSelectItemAtIndexPath(id self, SEL _cmd, id collectionView, id indexPath){
    SEL selector = NSSelectorFromString(@"swizzle_didSelectItemAtIndexPath");
    ((void(*)(id, SEL, id, id))objc_msgSend)(self, selector, collectionView, indexPath);
    [AutoTrackUtils trackAppClickWithUICollectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

void sa_setDelegate(id obj ,SEL sel, id delegate){
    SEL swizzileSel = sel_getUid("sa_setDelegate:");
    ((void (*)(id, SEL,id))objc_msgSend)(obj,swizzileSel,delegate);
    if (delegate == nil) {
        return;
    }
    if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled]){
        if ([obj isKindOfClass:UITableView.class]) {
            if ([delegate isKindOfClass:[UITableView class]]) {
                return;
            }
            if ([NSObject hasMethod:[delegate class] sel:@selector(tableView:didSelectRowAtIndexPath:)]){
                SEL swizSel = NSSelectorFromString(@"swizzle_didSelectRowAtIndexPath");
                if ([NSObject addMethod:[delegate class] sel:swizSel method:(IMP)swizzle_didSelectRowAtIndexPath]) {
                    if (![arrChachedClassForTableViewDelegate containsObject:NSStringFromClass([delegate class])]) {
                        [NSObject swapMethod:[delegate class] origMethod:swizSel newMethod:@selector(tableView:didSelectRowAtIndexPath:)];
                        [arrChachedClassForTableViewDelegate addObject:NSStringFromClass([delegate class])];
                    }
                }
            }
        }else if ([obj isKindOfClass:UICollectionView.class]){
            if ([delegate isKindOfClass:[UICollectionView class]]) {
                return;
            }
            if ([NSObject hasMethod:[delegate class] sel:@selector(collectionView:didSelectItemAtIndexPath:)]){
                SEL swizSel = NSSelectorFromString(@"swizzle_didSelectItemAtIndexPath");
                if ([NSObject addMethod:[delegate class] sel:swizSel method:(IMP)swizzle_didSelectItemAtIndexPath]) {
                     if (![arrChachedClassForCollectionViewDelegate containsObject:NSStringFromClass([delegate class])]) {
                         [NSObject swapMethod:[delegate class] origMethod:swizSel newMethod:@selector(collectionView:didSelectItemAtIndexPath:)];
                         [arrChachedClassForCollectionViewDelegate addObject:NSStringFromClass([delegate class])];
                     }
                }
            }
        }
    }
}

@implementation NSObject (SensorsAnalyticsDelegate)
-(void)setSensorsAnalyticsDelegateProxy:(SADelegateProxy *)SensorsAnalyticsDelegateProxy{
    objc_setAssociatedObject(self, @selector(setSensorsAnalyticsDelegateProxy:), SensorsAnalyticsDelegateProxy, OBJC_ASSOCIATION_RETAIN);
}
-(SADelegateProxy *)sensorsAnalyticsDelegateProxy{
    return objc_getAssociatedObject(self, @selector(setSensorsAnalyticsDelegateProxy:));
}

+ (BOOL)addMethod:(Class)class sel:(SEL)sel method:(IMP)method{
    return class_addMethod(class, sel, method, "v@:@@");
}

+ (void)swapMethod:(Class)class origMethod:(SEL)origSelector newMethod:(SEL)newSelector{
    Method originalMethod = class_getInstanceMethod(class, origSelector);
    Method swizzledMethod = class_getInstanceMethod(class, newSelector);
    method_exchangeImplementations(originalMethod, swizzledMethod);
}
+ (BOOL)hasMethod:(Class)class sel:(SEL)sel{
    BOOL hasMethod = NO;
    unsigned int count = 0;
    Method *methodList = class_copyMethodList(class, &count);
    for (unsigned int i = 0; i < count; i++ ) {
        Method method = methodList[i];
        SEL methodName = method_getName(method);
        if ([NSStringFromSelector(methodName) isEqualToString:NSStringFromSelector(sel)]) {
            hasMethod = YES;break;
        }
    }
    free(methodList);
    return hasMethod;
}

@end

@implementation UITableView (SensorsAnalyticsDelegate)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        arrChachedClassForTableViewDelegate = [[NSMutableArray alloc]init];
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

@implementation UICollectionView (SensorsAnalyticsDelegate)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        arrChachedClassForCollectionViewDelegate = [[NSMutableArray alloc]init];
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

#endif
