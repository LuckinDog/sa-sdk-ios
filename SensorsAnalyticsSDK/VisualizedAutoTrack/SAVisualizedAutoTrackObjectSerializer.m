//
//  SAObjectSerializer.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import <objc/runtime.h>
#import <WebKit/WebKit.h>
#import "NSInvocation+SAHelpers.h"
#import "SAClassDescription.h"
#import "SAEnumDescription.h"
#import "SALog.h"
#import "SAObjectIdentityProvider.h"
#import "SAVisualizedAutoTrackObjectSerializer.h"
#import "SAObjectSerializerConfig.h"
#import "SAObjectSerializerContext.h"
#import "SAPropertyDescription.h"
#import "UIView+VisualizedAutoTrack.h"
#import "SAAutoTrackProperty.h"
#import "SAAutoTrackUtils.h"
#import "SAJSTouchEventView.h"
#import "SAVisualizedObjectSerializerManger.h"
#import "SensorsAnalyticsSDK+Private.h"

@interface SAVisualizedAutoTrackObjectSerializer ()
@end

@implementation SAVisualizedAutoTrackObjectSerializer {
    SAObjectSerializerConfig *_configuration;
    SAObjectIdentityProvider *_objectIdentityProvider;
}

- (instancetype)initWithConfiguration:(SAObjectSerializerConfig *)configuration
               objectIdentityProvider:(SAObjectIdentityProvider *)objectIdentityProvider {
    self = [super init];
    if (self) {
        _configuration = configuration;
        _objectIdentityProvider = objectIdentityProvider;
    }
    
    return self;
}

- (NSDictionary *)serializedObjectsWithRootObject:(id)rootObject {
    NSParameterAssert(rootObject != nil);
    
    SAObjectSerializerContext *context = [[SAObjectSerializerContext alloc] initWithRootObject:rootObject];
    
    @try {// 遍历 _unvisitedObjects 中所有元素，解析元素信息
        while ([context hasUnvisitedObjects]) {
            [self visitObject:[context dequeueUnvisitedObject] withContext:context];
        }
    } @catch (NSException *e) {
        SALogError(@"Failed to serialize objects: %@", e);
    }
    
    NSMutableDictionary *serializedObjects = [NSMutableDictionary dictionaryWithDictionary:@{
        @"objects" : [context allSerializedObjects],
        @"rootObject": [_objectIdentityProvider identifierForObject:rootObject]
    }];
    return [serializedObjects copy];
}

- (void)visitObject:(NSObject *)object withContext:(SAObjectSerializerContext *)context {
    NSParameterAssert(object != nil);
    NSParameterAssert(context != nil);

    [context addVisitedObject:object];

    // 获取构建单个元素的所有属性
    NSMutableDictionary *propertyValues = [[NSMutableDictionary alloc] init];

    // 获取当前类以及父类页面结构需要的 name,superclass、properties
    SAClassDescription *classDescription = [self classDescriptionForObject:object];
    if (classDescription) {
        // 遍历自身和父类的所需的属性及类型，合并为当前类所有属性
        for (SAPropertyDescription *propertyDescription in [classDescription propertyDescriptions]) {
            if ([propertyDescription shouldReadPropertyValueForObject:object]) {
                //  根据是否符号要求（是否显示等）构建属性，通过 KVC 和 NSInvocation 动态调用获取描述信息
                id propertyValue = [self propertyValueForObject:object withPropertyDescription:propertyDescription context:context]; // $递增作为元素 id
                propertyValues[propertyDescription.key] = propertyValue ? : [NSNull null];
            }
        }
    }

    if (
#ifdef SENSORS_ANALYTICS_DISABLE_UIWEBVIEW
        [NSStringFromClass(object.class) isEqualToString:@"UIWebView"] ||
#else
        [object isKindOfClass:UIWebView.class]
#endif
        ) { // 暂不支持 UIWebView
        [[SAVisualizedObjectSerializerManger sharedInstance] enterWebViewPageWithWebInfo:nil];

        NSMutableDictionary *alertInfo = [NSMutableDictionary dictionary];
        alertInfo[@"title"] = @"温馨提示";
        alertInfo[@"message"] = @"此页面包含 UIWebView，App 内嵌 H5 可视化全埋点，暂时只支持 WKWebView";

#warning App 内嵌 H5 只支持 WKWebView，针对 UIWebView，弹框提示文案待确认，链接后期需要换到正式的 App 内嵌 H5 可视化全埋点的文档说明

        alertInfo[@"link_text"] = @"参照文档";
        alertInfo[@"link_url"] = @"https://manual.sensorsdata.cn/sa/latest/visual_auto_track-7541326.html";
        [[SAVisualizedObjectSerializerManger sharedInstance] registWebAlertInfos:@[alertInfo]];
    } else if ([object isKindOfClass:WKWebView.class]) {
        WKWebView *webView = (WKWebView *)object;

        // H5 页面信息
        NSDictionary *pageInfo = webView.sensorsdata_webPageInfo;
        if (pageInfo) {
            SAVisualizedWebPageInfo *webPageInfo = [[SAVisualizedWebPageInfo alloc] init];
            webPageInfo.title = pageInfo[@"$title"];
            webPageInfo.url = pageInfo[@"$url"];
            [[SAVisualizedObjectSerializerManger sharedInstance] enterWebViewPageWithWebInfo:webPageInfo];
        }

        // H5 弹框信息
        NSArray *alertInfos = webView.sensorsdata_webAlertInfos;
        if (alertInfos.count > 0) {
            [[SAVisualizedObjectSerializerManger sharedInstance] registWebAlertInfos:alertInfos];
        }

        // H5 元素可点击元素信息
        NSDictionary *webviewProperties = webView.sensorsdata_extensionProperties;

        WKUserContentController *contentController = webView.configuration.userContentController;
        NSArray<WKUserScript *> *userScripts = contentController.userScripts;
        __block BOOL isContainVisualized = NO;
        [userScripts enumerateObjectsUsingBlock:^(WKUserScript *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj.source containsString:@"sensorsdata_visualized_mode"]) {
                isContainVisualized = YES;
                *stop = YES;
            }
        }];

        /*
         isContainVisualized 防止重复注入标记（js 发送数据，是异步的，防止 sensorsdata_visualized_mode 已经注入完成，但是尚未接收到 js 数据）
         可能延迟开启可视化全埋点，未成功注入标记，手动通知 JS 发送数据
         */
        if (!isContainVisualized && !(webviewProperties || alertInfos || pageInfo)) {
            // 注入 bridge 属性值，标记当前处于可视化全埋点调试
            NSMutableString *javaScriptSource = [NSMutableString string];
            [javaScriptSource appendString:@"window.SensorsData_App_Visual_Bridge.sensorsdata_visualized_mode = true;"];

            // 通知 js 发送页面数据
            [javaScriptSource appendString:@"window.sensorsdata_app_call_js('visualized')"];

            [webView evaluateJavaScript:javaScriptSource completionHandler:^(id _Nullable response, NSError *_Nullable error) {
                if (error) {
                    SALogError(@"window.sensorsdata_app_call_js error：%@", error);
                }
            }];
        }

        // 延时检测是否集成 JS SDK
        dispatch_queue_t jsCallQueue = dispatch_queue_create("sensorsData-JSCall", DISPATCH_QUEUE_SERIAL);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), jsCallQueue, ^{
            if (isContainVisualized && !(webviewProperties || alertInfos || pageInfo)) {
                NSString *javaScript = @"window.sensorsdata_app_call_js('test')";

                [webView evaluateJavaScript:javaScript completionHandler:^(id _Nullable response, NSError *_Nullable error) {
                    if (error) {
                        SALogError(@"window.sensorsdata_app_call_js error：%@", error);
                    }
                }];
            }
        });
    }

    NSArray *classNames = [self classHierarchyArrayForObject:object];
    if ([object isKindOfClass:SAJSTouchEventView.class]) {
        SAJSTouchEventView *touchView = (SAJSTouchEventView *)object;
        propertyValues[@"is_h5"] = @(YES);
        classNames = @[touchView.tagName];
    } else {
        propertyValues[@"is_h5"] = @(NO);
    }

    // 记录当前可点击元素所在的 viewController
    if ([object isKindOfClass:UIView.class] && [object respondsToSelector:@selector(sensorsdata_enableAppClick)] && [object respondsToSelector:@selector(sensorsdata_viewController)]) {
        UIView <SAAutoTrackViewProperty> *view = (UIView <SAAutoTrackViewProperty> *)object;
        UIViewController *viewController = [view sensorsdata_viewController];
        if (viewController && view.sensorsdata_enableAppClick) {
            [[SAVisualizedObjectSerializerManger sharedInstance] enterViewController:viewController];
        }
    }

    propertyValues[@"element_level"] = @([context currentLevelIndex]);
    NSDictionary *serializedObject = @{ @"id": [_objectIdentityProvider identifierForObject:object],
                                        @"class": classNames, // 遍历获取父类名称
                                        @"properties": propertyValues };

    [context addSerializedObject:serializedObject];
}
- (NSArray *)classHierarchyArrayForObject:(NSObject *)object {
    NSMutableArray *classHierarchy = [[NSMutableArray alloc] init];
    
    Class aClass = [object class];
    while (aClass) {
        [classHierarchy addObject:NSStringFromClass(aClass)];
        aClass = [aClass superclass];
    }
    return [classHierarchy copy];
}

- (NSInvocation *)invocationForObject:(id)object
              withSelectorDescription:(SAPropertySelectorDescription *)selectorDescription {
    
    SEL aSelector = NSSelectorFromString(selectorDescription.selectorName);
    NSAssert(aSelector != nil, @"Expected non-nil selector!");
    
    NSMethodSignature *methodSignature = [object methodSignatureForSelector:aSelector];
    NSInvocation *invocation = nil;
    
    if (methodSignature) {
        NSAssert([methodSignature numberOfArguments] == 2, @"Unexpected number of arguments!");
        
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        invocation.selector = aSelector;
    }
    return invocation;
}

- (id)propertyValue:(id)propertyValue
propertyDescription:(SAPropertyDescription *)propertyDescription
           context : (SAObjectSerializerContext *)context {
    
    if ([context isVisitedObject:propertyValue]) {
        return [_objectIdentityProvider identifierForObject:propertyValue];
    }

    if ([self isNestedObjectType:propertyDescription.type]) {
        [context enqueueUnvisitedObject:propertyValue];
        return [_objectIdentityProvider identifierForObject:propertyValue];
    }

    if ([propertyValue isKindOfClass:[NSArray class]] || [propertyValue isKindOfClass:[NSSet class]]) {
        NSMutableArray *arrayOfIdentifiers = [[NSMutableArray alloc] init];
        if ([propertyValue isKindOfClass:[NSArray class]]) {
            [context enqueueUnvisitedObjects:propertyValue];
        } else if ([propertyValue isKindOfClass:[NSSet class]]) {
            [context enqueueUnvisitedObjects:[(NSSet *)propertyValue allObjects]];
        }

        for (id value in propertyValue) {
            [arrayOfIdentifiers addObject:[_objectIdentityProvider identifierForObject:value]];
        }
        propertyValue = [arrayOfIdentifiers copy];
    }

    return [propertyDescription.valueTransformer transformedValue:propertyValue];
}

- (id)propertyValueForObject:(NSObject *)object
     withPropertyDescription:(SAPropertyDescription *)propertyDescription
                    context : (SAObjectSerializerContext *)context {
    SAPropertySelectorDescription *selectorDescription = propertyDescription.getSelectorDescription;
    
    // 使用 kvc 解析属性
    if (propertyDescription.useKeyValueCoding) {
        // the "fast" (also also simple) path is to use KVC
        
        id valueForKey = [object valueForKey:selectorDescription.selectorName];
        
        // 将获取到的属性属于 classes 中的元素添加到 _unvisitedObjects 中，递增生成当前元素唯一 Id
        id value = [self propertyValue:valueForKey
                   propertyDescription:propertyDescription
                               context:context];
        
        return value;
    } else {
        // the "slow" NSInvocation path. Required in order to invoke methods that take parameters.
        
        // 通过 NSInvocation 构造并动态调用 selector，获取元素描述信息
        NSInvocation *invocation = [self invocationForObject:object withSelectorDescription:selectorDescription];
        if (invocation) {
            [invocation sa_setArgumentsFromArray:@[]];
            [invocation invokeWithTarget:object];
            
            id returnValue = [invocation sa_returnValue];
            
            if ([object isKindOfClass:[UICollectionView class]]) {
                NSString *name = propertyDescription.name;
                if ([name isEqualToString:@"sensorsdata_subElements"]) {
                    @try {
                        NSArray *result = [returnValue sortedArrayUsingComparator:^NSComparisonResult (UIView *obj1, UIView *obj2) {

                            if (obj2.frame.origin.y > obj1.frame.origin.y || obj2.frame.origin.x > obj1.frame.origin.x) {
                                return NSOrderedDescending;
                            }
                            return NSOrderedAscending;
                        }];
                        returnValue = [result copy];
                    } @catch (NSException *exception) {
                        SALogError(@"Failed to sensorsdata_subElements for UICollectionView sorted: %@", exception);
                    }
                }
            }
            
            id value = [self propertyValue:returnValue
                       propertyDescription:propertyDescription
                                   context:context];
            if (value) {
                return value;
            }
        }
    }
    return nil;
}

- (BOOL)isNestedObjectType:(NSString *)typeName {
    return [_configuration classWithName:typeName] != nil;
}

- (SAClassDescription *)classDescriptionForObject:(NSObject *)object {
    NSParameterAssert(object != nil);
    
    Class aClass = [object class];
    while (aClass != nil) {
        SAClassDescription *classDescription = [_configuration classWithName:NSStringFromClass(aClass)];
        if (classDescription) {
            return classDescription;
        }
        
        aClass = [aClass superclass];
    }
    
    return nil;
}

@end
