//
//  SANetwork.m
//  SensorsAnalyticsSDK
//
//  Created by 张敏超 on 2019/3/8.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "SANetwork.h"
#import "SAURLUtils.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SensorsAnalyticsSDK.h"
#import "NSString+HashCode.h"
#import "SAGzipUtility.h"
#import "SALog.h"
#import "SAJSONUtil.h"
#import "SAHTTPSession.h"

@interface SANetwork ()
/// 存储原始的 ServerURL，当修改 DebugMode 为 Off 时，会使用此值去设置 ServerURL
@property (nonatomic, readwrite, strong) NSURL *originServerURL;

//@property (nonatomic, strong) NSOperationQueue *delegateQueue;
@property (nonatomic, strong) SAHTTPSession *session;
@property (nonatomic, copy) NSString *cookie;

@end

@implementation SANetwork

#pragma mark - init
- (instancetype)initWithServerURL:(NSURL *)serverURL session:(SAHTTPSession *)session {
    self = [super init];
    if (self) {
//        _delegateQueue = queue;
        _session = session;

        self.serverURL = serverURL;
    }
    return self;
}

#pragma mark - property
- (void)setServerURL:(NSURL *)serverURL {
    _originServerURL = serverURL;
    if (self.debugMode == SensorsAnalyticsDebugOff || serverURL == nil) {
        _serverURL = serverURL;
    } else {
        // 将 Server URI Path 替换成 Debug 模式的 '/debug'
        if (serverURL.lastPathComponent.length > 0) {
            serverURL = [serverURL URLByDeletingLastPathComponent];
        }
        NSURL *url = [serverURL URLByAppendingPathComponent:@"debug"];
        if ([url.host rangeOfString:@"_"].location != NSNotFound) { //包含下划线日志提示
            NSString * referenceURL = @"https://en.wikipedia.org/wiki/Hostname";
            SALogWarn(@"Server url:%@ contains '_'  is not recommend,see details:%@", serverURL.absoluteString, referenceURL);
        }
        _serverURL = url;
    }
}

- (void)setDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    _debugMode = debugMode;
    self.serverURL = _originServerURL;
}

- (void)setSecurityPolicy:(SASecurityPolicy *)securityPolicy {
    if (securityPolicy.SSLPinningMode != SASSLPinningModeNone && ![self.serverURL.scheme isEqualToString:@"https"]) {
        NSString *pinningMode = @"Unknown Pinning Mode";
        switch (securityPolicy.SSLPinningMode) {
            case SASSLPinningModeNone:
                pinningMode = @"SASSLPinningModeNone";
                break;
            case SASSLPinningModeCertificate:
                pinningMode = @"SASSLPinningModeCertificate";
                break;
            case SASSLPinningModePublicKey:
                pinningMode = @"SASSLPinningModePublicKey";
                break;
        }
        NSString *reason = [NSString stringWithFormat:@"A security policy configured with `%@` can only be applied on a manager with a secure base URL (i.e. https)", pinningMode];
        @throw [NSException exceptionWithName:@"Invalid Security Policy" reason:reason userInfo:nil];
    }
    self.session.securityPolicy = securityPolicy;
}

- (SASecurityPolicy *)securityPolicy {
    return self.session.securityPolicy;
}

#pragma mark - cookie
- (void)setCookie:(NSString *)cookie isEncoded:(BOOL)encoded {
    if (encoded) {
        _cookie = [cookie stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    } else {
        _cookie = cookie;
    }
}

- (NSString *)cookieWithDecoded:(BOOL)isDecoded {
    return isDecoded ? _cookie.stringByRemovingPercentEncoding : _cookie;
}

#pragma mark -

#pragma mark - build
// 1. 先完成这一系列Json字符串的拼接
- (NSString *)buildFlushJSONStringWithEvents:(NSArray<NSString *> *)events {
    return [NSString stringWithFormat:@"[%@]", [events componentsJoinedByString:@","]];
}

- (NSURLRequest *)buildFlushRequestWithJSONString:(NSString *)jsonString HTTPMethod:(NSString *)HTTPMethod {
    NSString *postBody;
    @try {
        int gzip = 9; // gzip = 9 表示加密编码
        NSString *b64String = [jsonString copy];
#ifndef SENSORS_ANALYTICS_ENABLE_ENCRYPTION
        // 加密数据已经做过 gzip 压缩和 base64 处理了，就不需要再处理。
        gzip = 1;
        // 使用gzip进行压缩
        NSData *zippedData = [SAGzipUtility gzipData:[b64String dataUsingEncoding:NSUTF8StringEncoding]];
        // base64
        b64String = [zippedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
#endif

        int hashCode = [b64String sensorsdata_hashCode];
        b64String = [b64String stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
        postBody = [NSString stringWithFormat:@"crc=%d&gzip=%d&data_list=%@", hashCode, gzip, b64String];

    } @catch (NSException *exception) {
        SALogError(@"%@ flushByPost format data error: %@", self, exception);
        return nil;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.serverURL];
    request.timeoutInterval = 30;
    request.HTTPMethod = HTTPMethod;
    request.HTTPBody = [postBody dataUsingEncoding:NSUTF8StringEncoding];
    // 普通事件请求，使用标准 UserAgent
    [request setValue:@"SensorsAnalytics iOS SDK" forHTTPHeaderField:@"User-Agent"];
    if (self.debugMode == SensorsAnalyticsDebugOnly) {
        [request setValue:@"true" forHTTPHeaderField:@"Dry-Run"];
    }
    
    //Cookie
    [request setValue:[self cookieWithDecoded:NO] forHTTPHeaderField:@"Cookie"];
    return request;
}

- (NSURL *)buildDebugModeCallbackURLWithParams:(NSDictionary<NSString *, id> *)params {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:self.serverURL resolvingAgainstBaseURL:NO];
    NSString *queryString = [SAURLUtils urlQueryStringWithParams:params];
    if (urlComponents.query.length) {
        urlComponents.query = [NSString stringWithFormat:@"%@&%@", urlComponents.query, queryString];
    } else {
        urlComponents.query = queryString;
    }
    return urlComponents.URL;
}

- (NSURLRequest *)buildDebugModeCallbackRequestWithURL:(NSURL *)url distinctId:(NSString *)distinctId {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 30;
    [request setHTTPMethod:@"POST"];
    
    NSDictionary *callData = @{@"distinct_id": distinctId};
    NSData *jsonData = [SAJSONUtil JSONSerializeObject:callData];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    
    return request;
}

- (NSURLRequest *)buildFunctionalManagermentConfigRequestWithWithRemoteConfigURL:(nullable NSURL *)remoteConfigURL version:(NSString *)version {

    NSURLComponents *urlComponets = nil;
    if (remoteConfigURL) {
        urlComponets = [NSURLComponents componentsWithURL:remoteConfigURL resolvingAgainstBaseURL:YES];
    }
    if (!urlComponets.host) {
        NSURL *url = self.serverURL.lastPathComponent.length > 0 ? [self.serverURL URLByDeletingLastPathComponent] : self.serverURL;
        urlComponets = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
        if (urlComponets == nil) {
            SALogError(@"URLString is malformed, nil is returned.");
            return nil;
        }
        urlComponets.query = nil;
        urlComponets.path = [urlComponets.path stringByAppendingPathComponent:@"/config/iOS.conf"];
    }

    if (version.length) {
        urlComponets.query = [NSString stringWithFormat:@"v=%@", version];
    }
    return [NSURLRequest requestWithURL:urlComponets.URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
}

#pragma mark - request
- (BOOL)flushEvents:(NSArray<NSString *> *)events {
    if (![self isValidServerURL]) {
        SALogError(@"serverURL error，Please check the serverURL");
        return NO;
    }
    
    NSString *jsonString = [self buildFlushJSONStringWithEvents:events];

    __block BOOL flushSuccess = NO;
    dispatch_semaphore_t flushSemaphore = dispatch_semaphore_create(0);
    SAURLSessionTaskCompletionHandler handler = ^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
            SALogError(@"%@", [NSString stringWithFormat:@"%@ network failure: %@", self, error ? error : @"Unknown error"]);
            dispatch_semaphore_signal(flushSemaphore);
            return;
        }
        
        NSString *urlResponseContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSInteger statusCode = response.statusCode;
        NSString *messageDesc = nil;
        if (statusCode >= 200 && statusCode < 300) {
            messageDesc = @"\n【valid message】\n";
        } else {
            messageDesc = @"\n【invalid message】\n";
            if (statusCode >= 300 && self.debugMode != SensorsAnalyticsDebugOff) {
                NSString *errMsg = [NSString stringWithFormat:@"%@ flush failure with response '%@'.", self, urlResponseContent];
                [[SensorsAnalyticsSDK sharedInstance] showDebugModeWarning:errMsg withNoMoreButton:YES];
            }
        }
        // 1、开启 debug 模式，都删除；
        // 2、debugOff 模式下，只有 5xx & 404 & 403 不删，其余均删；
        BOOL successCode = (statusCode < 500 || statusCode >= 600) && statusCode != 404 && statusCode != 403;
        flushSuccess = self.debugMode != SensorsAnalyticsDebugOff || successCode;

        SALogDebug(@"==========================================================================");
        @try {
            NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
            SALogDebug(@"%@ %@: %@", self, messageDesc, dict);
        } @catch (NSException *exception) {
            SALogError(@"%@: %@", self, exception);
        }
        
        if (statusCode != 200) {
            SALogError(@"%@ ret_code: %ld, ret_content: %@", self, statusCode, urlResponseContent);
        }

        dispatch_semaphore_signal(flushSemaphore);
    };
    
    NSURLRequest *request = [self buildFlushRequestWithJSONString:jsonString HTTPMethod:@"POST"];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:handler];
    [task resume];

    dispatch_semaphore_wait(flushSemaphore, DISPATCH_TIME_FOREVER);

    return flushSuccess;
}

- (NSURLSessionTask *)debugModeCallbackWithDistinctId:(NSString *)distinctId params:(NSDictionary<NSString *, id> *)params {
    if (![self isValidServerURL]) {
        SALogError(@"serverURL error，Please check the serverURL");
        return nil;
    }
    NSURL *url = [self buildDebugModeCallbackURLWithParams:params];
    NSURLRequest *request = [self buildDebugModeCallbackRequestWithURL:url distinctId:distinctId];

    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        NSInteger statusCode = response.statusCode;
        if (statusCode == 200) {
            SALogDebug(@"config debugMode CallBack success");
        } else {
            SALogError(@"config debugMode CallBack Faild statusCode：%ld，url：%@", statusCode, url);
        }
    }];
    [task resume];
    return task;
}

- (NSURLSessionTask *)functionalManagermentConfigWithRemoteConfigURL:(nullable NSURL *)remoteConfigURL version:(NSString *)version completion:(void(^)(BOOL success, NSDictionary<NSString *, id> *config))completion {
    if (![self isValidServerURL]) {
        SALogError(@"serverURL error，Please check the serverURL");
        return nil;
    }
    NSURLRequest *request = [self buildFunctionalManagermentConfigRequestWithWithRemoteConfigURL:remoteConfigURL version:version];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!completion) {
            return ;
        }
        NSInteger statusCode = response.statusCode;
        BOOL success = statusCode == 200 || statusCode == 304;
        NSDictionary<NSString *, id> *config = nil;
        @try{
            if (statusCode == 200 && data.length) {
                config = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            }
        } @catch (NSException *e) {
            SALogError(@"%@ error: %@", self, e);
            success = NO;
        }
        completion(success, config);
    }];
    [task resume];
    return task;
}

@end

#pragma mark -
@implementation SANetwork (ServerURL)

- (NSString *)host {
    return [SAURLUtils hostWithURL:self.serverURL] ?: @"";
}

- (NSString *)project {
    return [SAURLUtils queryItemsWithURL:self.serverURL][@"project"] ?: @"default";
}

- (NSString *)token {
    return [SAURLUtils queryItemsWithURL:self.serverURL][@"token"] ?: @"";
}

- (BOOL)isSameProjectWithURLString:(NSString *)URLString {
    if (![self isValidServerURL] || URLString.length == 0) {
        return NO;
    }
    BOOL isEqualHost = [self.host isEqualToString:[SAURLUtils hostWithURLString:URLString]];
    NSString *project = [SAURLUtils queryItemsWithURLString:URLString][@"project"] ?: @"default";
    BOOL isEqualProject = [self.project isEqualToString:project];
    return isEqualHost && isEqualProject;
}

- (BOOL)isValidServerURL {
    return _serverURL.absoluteString.length > 0;
}

@end
