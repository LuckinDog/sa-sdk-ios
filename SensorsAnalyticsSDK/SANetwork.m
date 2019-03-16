//
//  SANetwork.m
//  SensorsAnalyticsSDK
//
//  Created by MC on 2019/3/8.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
//

#import "SANetwork.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SensorsAnalyticsSDK.h"
#import "NSString+HashCode.h"
#import "SAGzipUtility.h"
#import "SALogger.h"


typedef NSURLSessionAuthChallengeDisposition (^SAURLSessionDidReceiveAuthenticationChallengeBlock)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential);
typedef NSURLSessionAuthChallengeDisposition (^SAURLSessionTaskDidReceiveAuthenticationChallengeBlock)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential);

@interface SANetwork () <NSURLSessionDelegate, NSURLSessionTaskDelegate>
/// 存储原始的 ServerURL，当修改 DebugMode 为 Off 时，会使用此值去设置 ServerURL
@property (nonatomic, readwrite, strong) NSURL *originServerURL;

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy) NSString *cookie;

@property (nonatomic, copy) SAURLSessionDidReceiveAuthenticationChallengeBlock sessionDidReceiveAuthenticationChallenge;
@property (nonatomic, copy) SAURLSessionTaskDidReceiveAuthenticationChallengeBlock taskDidReceiveAuthenticationChallenge;

@end

@implementation SANetwork

#pragma mark - init
- (instancetype)init {
    self = [super init];
    if (self) {
        _securityPolicy = [SASecurityPolicy defaultPolicy];
        
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (instancetype)initWithServerURL:(NSURL *)serverURL debugMode:(SensorsAnalyticsDebugMode)debugMode {
    self = [super init];
    if (self) {
        _serverURL = serverURL;
        _debugMode = debugMode;
        
        _securityPolicy = [SASecurityPolicy defaultPolicy];
        
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
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
        if ([url.host containsString:@"_"]) { //包含下划线日志提示
            NSString * referenceURL = @"https://en.wikipedia.org/wiki/Hostname";
            SALog(@"Server url:%@ contains '_'  is not recommend,see details:%@", serverURL.absoluteString, referenceURL);
        }
        _serverURL = url;
    }
}

- (void)setDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    _debugMode = debugMode;
    self.serverURL = _originServerURL;
}

- (NSURLSession *)session {
    @synchronized (self) {
        if (!_session) {
            NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
            config.timeoutIntervalForRequest = 30.0;
            config.HTTPShouldUsePipelining = NO;
            _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:self.operationQueue];
        }
    }
    return _session;
}

- (void)setSecurityPolicy:(SASecurityPolicy *)securityPolicy {
    if (securityPolicy.SSLPinningMode != SASSLPinningModeNone && ![self.serverURL.scheme isEqualToString:@"https"]) {
        NSString *pinningMode = @"Unknown Pinning Mode";
        switch (securityPolicy.SSLPinningMode) {
            case SASSLPinningModeNone:        pinningMode = @"SASSLPinningModeNone"; break;
            case SASSLPinningModeCertificate: pinningMode = @"SASSLPinningModeCertificate"; break;
            case SASSLPinningModePublicKey:   pinningMode = @"SASSLPinningModePublicKey"; break;
        }
        NSString *reason = [NSString stringWithFormat:@"A security policy configured with `%@` can only be applied on a manager with a secure base URL (i.e. https)", pinningMode];
        @throw [NSException exceptionWithName:@"Invalid Security Policy" reason:reason userInfo:nil];
    }
    _securityPolicy = securityPolicy;
}

#pragma mark - cookie
- (void)setCookie:(NSString *)cookie withEncode:(BOOL)encode {
    if (encode) {
        _cookie = [cookie stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    } else {
        _cookie = cookie;
    }
}

- (NSString *)cookieWithDecode:(BOOL)decode {    
    return decode ? _cookie.stringByRemovingPercentEncoding : _cookie;
}

#pragma mark -

#pragma mark - build
// 1. 先完成这一系列Json字符串的拼接
- (NSString *)buildJSONStringWithEvents:(NSArray<NSString *> *)events {
    return [NSString stringWithFormat:@"[%@]", [events componentsJoinedByString:@","]];
}

- (NSURLRequest *)buildRequestWithJSONString:(NSString *)jsonString HTTPMethod:(NSString *)HTTPMethod {
    NSString *postBody;
    @try {
        // 2. 使用gzip进行压缩
        NSData *zippedData = [SAGzipUtility gzipData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
        // 3. base64
        NSString *b64String = [zippedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
        int hashCode = [b64String sensorsdata_hashCode];
        b64String = [b64String stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
        
        postBody = [NSString stringWithFormat:@"crc=%d&gzip=1&data_list=%@", hashCode, b64String];
    } @catch (NSException *exception) {
        SAError(@"%@ flushByPost format data error: %@", self, exception);
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
    [request setValue:[self cookieWithDecode:NO] forHTTPHeaderField:@"Cookie"];
    return request;
}

#pragma mark - flush
- (BOOL)flushEvents:(NSArray<NSString *> *)events {
    NSString *jsonString = [self buildJSONStringWithEvents:events];
    
    __block BOOL flushSuccess;
    dispatch_semaphore_t flushSemaphore = dispatch_semaphore_create(0);
    void (^handler)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable) = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
            SAError(@"%@", [NSString stringWithFormat:@"%@ network failure: %@", self, error ? error : @"Unknown error"]);
            dispatch_semaphore_signal(flushSemaphore);
            return;
        }
        
        NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse*)response;
        NSString *urlResponseContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSInteger statusCode = urlResponse.statusCode;
        NSString *messageDesc = statusCode == 200 ? @"\n【valid message】\n" : @"\n【invalid message】\n";
        if (statusCode >= 300 && self.debugMode != SensorsAnalyticsDebugOff) {
            NSString *errMsg = [NSString stringWithFormat:@"%@ flush failure with response '%@'.", self, urlResponseContent];
            [[SensorsAnalyticsSDK sharedInstance] showDebugModeWarning:errMsg withNoMoreButton:YES];
        }
        SAError(@"==========================================================================");
        if ([SALogger isLoggerEnabled]) {
            @try {
                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                NSString *logString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
                SAError(@"%@ %@: %@", self, messageDesc, logString);
            } @catch (NSException *exception) {
                SAError(@"%@: %@", self, exception);
            }
        }
        if (statusCode != 200) {
            SAError(@"%@ ret_code: %ld", self, statusCode);
            SAError(@"%@ ret_content: %@", self, urlResponseContent);
        }
        
        flushSuccess = YES;
        
        dispatch_semaphore_signal(flushSemaphore);
    };
    
    NSURLRequest *request = [self buildRequestWithJSONString:jsonString HTTPMethod:@"POST"];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:handler];
    [task resume];
    
    dispatch_semaphore_wait(flushSemaphore, DISPATCH_TIME_FOREVER);
    
    return flushSuccess;
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if (self.sessionDidReceiveAuthenticationChallenge) {
        disposition = self.sessionDidReceiveAuthenticationChallenge(session, challenge, &credential);
    } else {
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                if (credential) {
                    disposition = NSURLSessionAuthChallengeUseCredential;
                } else {
                    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                }
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if (self.taskDidReceiveAuthenticationChallenge) {
        disposition = self.taskDidReceiveAuthenticationChallenge(session, task, challenge, &credential);
    } else {
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                disposition = NSURLSessionAuthChallengeUseCredential;
                credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

@end

#pragma mark -
@implementation SANetwork (SessionAndTask)

- (void)setSessionDidReceiveAuthenticationChallengeBlock:(NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential))block {
    self.sessionDidReceiveAuthenticationChallenge = block;
}

- (void)setTaskDidReceiveAuthenticationChallengeBlock:(NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential))block {
    self.taskDidReceiveAuthenticationChallenge = block;
}

@end
