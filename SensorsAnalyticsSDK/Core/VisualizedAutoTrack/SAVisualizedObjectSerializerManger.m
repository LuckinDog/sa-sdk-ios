//
// SAVisualizedObjectSerializerManger.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/4/23.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAVisualizedObjectSerializerManger.h"
#import "SAJSONUtil.h"
#import "SALog.h"
#import "SAAutoTrackUtils.h"

@implementation SAVisualizedWebPageInfo

@end


@interface SAVisualizedObjectSerializerManger()

/// 是否包含 webview
@property (nonatomic, assign, readwrite) BOOL isContainWebView;

/// App 内嵌 H5 页面信息
@property (nonatomic, strong, readwrite) SAVisualizedWebPageInfo *webPageInfo;

/// 截图 hash 更新信息，如果存在，则添加到 image_hash 后缀
@property (nonatomic, copy, readwrite) NSString *imageHashUpdateMessage;

/// 上次截图 hash
@property (nonatomic, copy, readwrite) NSString *lastImageHash;

/// 记录当前栈中的 controller，不会持有
@property (nonatomic, strong) NSPointerArray *controllersStack;

/// 弹框信息
@property (nonatomic, strong, readwrite) NSMutableArray *alertInfos;

///  App 内嵌 H5 页面 缓存
/*
 key:H5 页面 url
 value:SAVisualizedWebPageInfo 对象
 */
@property (nonatomic, strong) NSMutableDictionary <NSString *,SAVisualizedWebPageInfo *>*webPageInfoCache;

@end

@implementation SAVisualizedObjectSerializerManger

+ (instancetype)sharedInstance {
    static SAVisualizedObjectSerializerManger *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SAVisualizedObjectSerializerManger alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initializeObjectSerializer];
    }
    return self;
}

- (void)initializeObjectSerializer {

    /* NSPointerArray 使用 weakObjectsPointerArray 初始化
     对于集合中的对象不会强引用，如果对象被释放，则会被置为 NULL，调用 compact 即可移除所有 NULL 对象
     */
    _controllersStack = [NSPointerArray weakObjectsPointerArray];
    _alertInfos = [NSMutableArray array];
    _webPageInfoCache = [NSMutableDictionary dictionary];

    _isContainWebView = NO;
}

/// 重置解析配置
- (void)resetObjectSerializer {
    self.isContainWebView = NO;

    self.webPageInfo = nil;
    [self.alertInfos removeAllObjects];
}

- (void)cleanVisualizedWebPageInfoCache {
    [self.webPageInfoCache removeAllObjects];

    self.imageHashUpdateMessage = nil;
    self.lastImageHash = nil;
}

/// 刷新截图 imageHash 信息
- (void)refreshImageHashWithData:(id)obj {
    /*
      App 内嵌 H5 的可视化全埋点，可能页面加载完成，但是未及时接收到 Html 页面信息。
      等接收到 JS SDK 发送的页面信息，由于页面截图不变，前端页面未重新加载解析 viewTree 信息，导致无法圈选。
      所以，接收到 JS 的页面信息，在原有 imageHash 基础上拼接 html 页面数据 hash 值，使得前端重新加载页面信息
      */
    NSData *jsonData = nil;
    @try {
        jsonData = [SAJSONUtil JSONSerializeObject:obj];
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }

    if (jsonData) {
        NSUInteger hashCode = [jsonData hash];
        self.imageHashUpdateMessage = [NSString stringWithFormat:@"%lu", (unsigned long)hashCode];
    }
}

/// 缓存可视化全埋点相关 web 信息
- (void)saveVisualizedWebPageInfoWithWebView:(WKWebView *)webview webPageInfo:(NSDictionary *)pageInfo {

    NSString *callType = pageInfo[@"callType"];
    if (([callType isEqualToString:@"visualized_track"])) {
        // H5 页面可点击元素数据
        NSArray *pageDatas = pageInfo[@"data"];
        if ([pageDatas isKindOfClass:NSArray.class]) {
            NSDictionary *elementInfo = [pageDatas firstObject];
            NSString *url = elementInfo[@"$url"];
            if (url) {
                SAVisualizedWebPageInfo *webPageInfo = [[SAVisualizedWebPageInfo alloc] init];
                // 是否包含当前 url 的页面信息
                if ([self.webPageInfoCache objectForKey:url]) {
                    webPageInfo = self.webPageInfoCache[url];

                    // 更新 H5 元素信息，则可视化全埋点可用，此时清空弹框信息
                    webPageInfo.alertSources = nil;
                }
                webPageInfo.elementSources = pageDatas;
                self.webPageInfoCache[url] = webPageInfo;

                // 刷新数据
                [self refreshImageHashWithData:pageDatas];
            }
        }
    } else if ([callType isEqualToString:@"app_alert"]) { // 弹框提示信息
        /*
         [{
         "title": "弹框标题",
         "message": "App SDK 与 Web SDK 没有进行打通，请联系贵方技术人员修正 Web SDK 的配置，详细信息请查看文档。",
         "link_text": "配置文档"
         "link_url": "https://manual.sensorsdata.cn/sa/latest/app-h5-1573913.html"
         }]
         */
        NSArray <NSDictionary *> *alertDatas = pageInfo[@"data"];
        NSString *url = webview.URL.absoluteString;
        if ([alertDatas isKindOfClass:NSArray.class] && url) {
            SAVisualizedWebPageInfo *webPageInfo = [[SAVisualizedWebPageInfo alloc] init];
            // 是否包含当前 url 的页面信息
            if ([self.webPageInfoCache objectForKey:url]) {
                webPageInfo = self.webPageInfoCache[url];

                // 如果 js 发送弹框信息，即 js 环境变化，可视化全埋点不可用，则清空页面信息
                webPageInfo.elementSources = nil;
                webPageInfo.url = nil;
                webPageInfo.title = nil;
            }
            webPageInfo.alertSources = alertDatas;
            self.webPageInfoCache[url] = webPageInfo;
            // 刷新数据
            [self refreshImageHashWithData:alertDatas];
        }
    } else if (([callType isEqualToString:@"page_info"])) { // h5 页面信息
        NSDictionary *webInfo = pageInfo[@"data"];
        NSString *url = webInfo[@"$url"];
        if ([webInfo isKindOfClass:NSDictionary.class] && url) {
            SAVisualizedWebPageInfo *webPageInfo = [[SAVisualizedWebPageInfo alloc] init];
            // 是否包含当前 url 的页面信息
            if ([self.webPageInfoCache objectForKey:url]) {
                webPageInfo = self.webPageInfoCache[url];

                // 更新 H5 页面信息，则可视化全埋点可用，此时清空弹框信息
                webPageInfo.alertSources = nil;
            }
            webPageInfo.url = url;
            webPageInfo.title = webInfo[@"$title"];
            self.webPageInfoCache[url] = webPageInfo;
            // 刷新数据
            [self refreshImageHashWithData:webInfo];
        }
    }
}

/// 读取当前 webView 页面信息
- (SAVisualizedWebPageInfo *)readWebPageInfoWithWebView:(WKWebView *)webView {
    NSString *url = webView.URL.absoluteString;
    SAVisualizedWebPageInfo *webPageInfo = [self.webPageInfoCache objectForKey:url];
    return webPageInfo;
}

- (void)enterWebViewPageWithWebInfo:(SAVisualizedWebPageInfo *)webInfo; {
    self.isContainWebView = YES;
    if (webInfo) {
        self.webPageInfo = webInfo;
    }
}

/// 进入页面
- (void)enterViewController:(UIViewController *)viewController {
    // 每次 compact 之前需要添加 NULL，规避系统 Bug（compact 函数有个已经报备的 bug，每次 compact 之前需要添加一个 NULL，否则会 compact 失败）
    [self.controllersStack addPointer:NULL];
    [self.controllersStack compact];

    // 移除可能已经存在的 viewController
    NSArray *allObjects = self.controllersStack.allObjects;
    if ([allObjects containsObject:viewController]) {
        NSInteger index = [allObjects indexOfObject:viewController];
        [self.controllersStack removePointerAtIndex:index];
    }

    [self.controllersStack addPointer:(__bridge void * _Nullable)(viewController)];
}

- (UIViewController *)lastViewScreenController {
    // allObjects 会自动过滤 NULL
    NSArray *allObjects = [self.controllersStack allObjects];
    NSUInteger objectCount = allObjects.count;
    if (objectCount == 0) {
        return nil;
    }
    return [allObjects objectAtIndex:objectCount - 1];
}

- (void)resetLastImageHash:(NSString *)imageHash {
    self.lastImageHash = imageHash;
    self.imageHashUpdateMessage = nil;
}

- (void)registWebAlertInfos:(NSArray <NSDictionary *> *)infos {
    if (infos.count == 0) {
        return;
    }
    // 通过 Dictionary 构造所有不同 message 的弹框集合
    NSMutableDictionary *alertMessageInfoDic = [NSMutableDictionary dictionary];
    for (NSDictionary *alertInfo in self.alertInfos) {
        NSString *message = alertInfo[@"message"];
        if (message) {
            alertMessageInfoDic[message] = alertInfo;
        }
    }

    // 只添加 message 不重复的弹框信息
    for (NSDictionary *alertInfo in infos) {
        NSString *message = alertInfo[@"message"];
        if (message && ![alertMessageInfoDic.allKeys containsObject:message]) {
            [self.alertInfos addObject:alertInfo];
        }
    }

    // 强制刷新数据
    [self refreshImageHashWithData:infos];
}
@end
