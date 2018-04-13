//
//  SensorsAnalyticsSDKController.m
//  SensorsAnalyticsSDKController
//
//  Created by ziven.mac on 2018/4/12.
//  Copyright © 2018年 SensorsData. All rights reserved.
//
#import "SALogger.h"
#import "SensorsAnalyticsSDKController.h"
#import <objc/runtime.h>
#import "SensorsAnalyticsSDK.h"
static NSMutableDictionary *__originIMPCache__ = nil;
@interface IMPCacheObj :NSObject
@property(nonatomic,assign)SEL sel;
@property(nonatomic,assign)IMP originalIMP;
@end
@implementation IMPCacheObj
@end
@implementation SensorsAnalyticsSDKController
+(void)initialize{
    __originIMPCache__ = [[NSMutableDictionary alloc]init];
    unsigned int method_count = 0;
    Method  *method_list =  class_copyMethodList([SensorsAnalyticsSDK class],&method_count );
    for (int i =0; i<method_count; i++) {
        Method temp_method = method_list[i];
        SEL selector = method_getName(temp_method);
        IMP origin_imp = method_getImplementation(temp_method);
        if (origin_imp != (IMP)hookCommonIMP) {
            IMPCacheObj * obj = [[IMPCacheObj alloc]init];
            obj.originalIMP = origin_imp;
            obj.sel = selector;
            [__originIMPCache__ setObject:obj forKey:NSStringFromSelector(selector)];
        }
    }
    free(method_list);
}
+(void)disableAllFunctionOriginIMP{
    unsigned int method_count = 0;
    Method  *method_list =  class_copyMethodList([SensorsAnalyticsSDK class],&method_count );
    for (int i =0; i<method_count; i++) {
        Method temp_method = method_list[i];
        IMP origin_imp = method_getImplementation(temp_method);
        if (origin_imp != (IMP)hookCommonIMP) {
            method_setImplementation(temp_method, (IMP)hookCommonIMP);
        }
    }
    free(method_list);
}

id hookCommonIMP(id obj, SEL sel,...){
    NSMutableString *format = [NSMutableString stringWithFormat:@"%@,%@",obj,NSStringFromSelector(sel)];
    va_list arg_ptr;
    va_start(arg_ptr, sel);
    NSMethodSignature *signature = [obj methodSignatureForSelector:sel];
    NSUInteger length = [signature numberOfArguments];
    for (NSUInteger i = 2; i < length; i++) {
        void *parameter = va_arg(arg_ptr, void *);
        [format appendFormat: @",%p ",parameter];
    }
    va_end(arg_ptr);
    SALog(@"%@",format);
    return nil;
}

+(void)enableOriginFunctionIMP{
    unsigned int method_count = 0;
    Method  *method_list =  class_copyMethodList([SensorsAnalyticsSDK class],&method_count );
    for (int i =0; i<method_count; i++) {
        Method temp_method = method_list[i];
        SEL selector = method_getName(temp_method);
        IMP origin_imp = method_getImplementation(temp_method);
        if (origin_imp == (IMP)hookCommonIMP) {
            IMPCacheObj *obj = [__originIMPCache__ objectForKey:NSStringFromSelector(selector)];
            method_setImplementation(temp_method, obj.originalIMP);
        }
    }
    free(method_list);
}
@end
