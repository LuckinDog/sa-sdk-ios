//
// SensorsAnalyticsSDK+SAWebView.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/8/12.
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

//#if __has_include("SensorsAnalyticsSDK+WKWebView.h")
//#error This file cannot exist at the same time with `SensorsAnalyticsSDK+WKWebView.h`. If you use `UIWebView`, please delete it.
//#endif

#import "SensorsAnalyticsSDK+UIWebView.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SensorsAnalyticsSDK.h"
#import "SAConstants+Private.h"
#import "SACommonUtility.h"
#import "SAConstants.h"
#import "SAJSONUtil.h"
#import "SAURLUtils.h"
#import "SALog.h"

static NSString* const SA_JS_GET_APP_INFO_SCHEME = @"sensorsanalytics://getAppInfo";
static NSString* const SA_JS_TRACK_EVENT_NATIVE_SCHEME = @"sensorsanalytics://trackEvent";

@interface SensorsAnalyticsSDK (SAWebViewPrivate)

@property (atomic, copy) NSString *userAgent;

- (BOOL)shouldHandleWebView:(id)webView request:(NSURLRequest *)request;

- (NSMutableDictionary *)webViewJavascriptBridgeCallbackInfo;

@end

@implementation SensorsAnalyticsSDK (UIWebView)

- (void)loadUserAgentWithCompletion:(void (^)(NSString *))completion {
    if (self.userAgent) {
        return completion(self.userAgent);
    }
    [SACommonUtility performBlockOnMainThread:^{
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        self.userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        completion(self.userAgent);
    }];
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request andProperties:(NSDictionary *)propertyDict enableVerify:(BOOL)enableVerify {
    if (![self shouldHandleWebView:webView request:request]) {
        return NO;
    }
    
    @try {
        SALogDebug(@"showUpWebView");
        NSDictionary *bridgeCallbackInfo = [self webViewJavascriptBridgeCallbackInfo];
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        if (bridgeCallbackInfo) {
            [properties addEntriesFromDictionary:bridgeCallbackInfo];
        }
        if (propertyDict) {
            [properties addEntriesFromDictionary:propertyDict];
        }
        NSData *jsonData = [SAJSONUtil JSONSerializeObject:properties];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        NSString *js = [NSString stringWithFormat:@"sensorsdata_app_js_bridge_call_js('%@')", jsonString];

        //判断系统是否支持WKWebView
        Class wkWebViewClass = NSClassFromString(@"WKWebView");

        NSString *urlstr = request.URL.absoluteString;
        if (!urlstr) {
            return YES;
        }

        //解析参数
        NSMutableDictionary *paramsDic = [[SAURLUtils queryItemsWithURLString:urlstr] mutableCopy];

        if ([webView isKindOfClass:[UIWebView class]]) {//UIWebView
            SALogDebug(@"showUpWebView: UIWebView");
            if ([urlstr rangeOfString:SA_JS_GET_APP_INFO_SCHEME].location != NSNotFound) {
                [webView stringByEvaluatingJavaScriptFromString:js];
            } else if ([urlstr rangeOfString:SA_JS_TRACK_EVENT_NATIVE_SCHEME].location != NSNotFound) {
                if ([paramsDic count] > 0) {
                    NSString *eventInfo = [paramsDic objectForKey:SA_EVENT_NAME];
                    if (eventInfo != nil) {
                        NSString *encodedString = [eventInfo stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        [self trackFromH5WithEvent:encodedString enableVerify:enableVerify];
                    }
                }
            }
        } else if (wkWebViewClass && [webView isKindOfClass:wkWebViewClass]) {//WKWebView
            SALogDebug(@"showUpWebView: WKWebView");
            if ([urlstr rangeOfString:SA_JS_GET_APP_INFO_SCHEME].location != NSNotFound) {
                typedef void (^Myblock)(id, NSError *);
                Myblock myBlock = ^(id _Nullable response, NSError *_Nullable error) {
                    SALogDebug(@"response: %@ error: %@", response, error);
                };
                SEL sharedManagerSelector = NSSelectorFromString(@"evaluateJavaScript:completionHandler:");
                if (sharedManagerSelector) {
                    ((void (*)(id, SEL, NSString *, Myblock))[webView methodForSelector:sharedManagerSelector])(webView, sharedManagerSelector, js, myBlock);
                }
            } else if ([urlstr rangeOfString:SA_JS_TRACK_EVENT_NATIVE_SCHEME].location != NSNotFound) {
                if ([paramsDic count] > 0) {
                    NSString *eventInfo = [paramsDic objectForKey:SA_EVENT_NAME];
                    if (eventInfo != nil) {
                        NSString *encodedString = [eventInfo stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        [self trackFromH5WithEvent:encodedString enableVerify:enableVerify];
                    }
                }
            }
        } else {
            SALogDebug(@"showUpWebView: not valid webview");
        }
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    } @finally {
        return YES;
    }
}

@end
