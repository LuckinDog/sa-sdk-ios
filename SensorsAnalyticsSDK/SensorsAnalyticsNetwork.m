//
//  SensorsAnalyticsNetwork.m
//  SensorsAnalyticsSDK
//
//  Created by MC on 2019/3/8.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
//

#import "SensorsAnalyticsNetwork.h"
#import "SensorsAnalyticsSDK.h"
#import "NSString+HashCode.h"
#import "SAGzipUtility.h"
#import "SALogger.h"

@interface SensorsAnalyticsNetwork () <NSURLSessionDelegate>

@property (nonatomic, strong) NSURL *serverURL;

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, copy) NSString *cookie;

@end

@implementation SensorsAnalyticsNetwork

#pragma mark - init
- (instancetype)initWithServerURL:(NSURL *)serverURL {
    self = [super init];
    if (self) {
        _serverURL = serverURL;
        
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

#pragma mark - getter
- (NSURLSession *)session {
    @synchronized (self) {
        if (!_session) {
            NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
            config.timeoutIntervalForRequest = 30.0;
            _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:self.operationQueue];
        }
    }
    return _session;
}

#pragma mark - cookie
- (void)setCookie:(NSString *)cookie withEncode:(BOOL)encode {
    if (encode) {
        _cookie = (id)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                (CFStringRef)cookie,
                                                                                NULL,
                                                                                CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                kCFStringEncodingUTF8));
        
    } else {
        _cookie = cookie;
    }
}

- (NSString *)cookieWithDecode:(BOOL)decode {
    return decode ? (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,(__bridge CFStringRef)_cookie, CFSTR(""), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) : _cookie;
}

#pragma mark - build
- (NSURLRequest *)buildRequestWithEvents:(NSArray<NSString *> *)events HTTPMethod:(NSString *)HTTPMethod {
    NSString *postBody;
    @try {
        // 1. 先完成这一系列Json字符串的拼接
        NSString *jsonString = [NSString stringWithFormat:@"[%@]", [events componentsJoinedByString:@","]];
        // 2. 使用gzip进行压缩
        NSData *zippedData = [SAGzipUtility gzipData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
        // 3. base64
        NSString *b64String = [zippedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
        int hashCode = [b64String sensorsdata_hashCode];
        b64String = (id)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                  (CFStringRef)b64String,
                                                                                  NULL,
                                                                                  CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                  kCFStringEncodingUTF8));
        
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
    if ([SensorsAnalyticsSDK sharedInstance].debugMode == SensorsAnalyticsDebugOnly) {
        [request setValue:@"true" forHTTPHeaderField:@"Dry-Run"];
    }
    
    //Cookie
    [request setValue:[self cookieWithDecode:NO] forHTTPHeaderField:@"Cookie"];
    return request;
}


#pragma mark - flush
- (void)flushEvents:(NSArray<NSString *> *)events {
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:self.serverURL];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req];
    [task resume];
}

- (void)flushEvents:(NSArray<NSString *> *)events completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    __block BOOL flushSucc = NO;
    dispatch_semaphore_t flushSem = dispatch_semaphore_create(0);
    void (^handler)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable) = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
            SAError(@"%@", [NSString stringWithFormat:@"%@ network failure: %@", self, error ? error : @"Unknown error"]);
            flushSucc = NO;
            dispatch_semaphore_signal(flushSem);
            return;
        }
        
        NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse*)response;
        NSString *urlResponseContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *errMsg = [NSString stringWithFormat:@"%@ flush failure with response '%@'.", self, urlResponseContent];
        NSString *messageDesc = nil;
        NSInteger statusCode = urlResponse.statusCode;
        if(statusCode != 200) {
            messageDesc = @"\n【invalid message】\n";
            if ([SensorsAnalyticsSDK sharedInstance].debugMode != SensorsAnalyticsDebugOff) {
                if (statusCode >= 300) {
//                    [self showDebugModeWarning:errMsg withNoMoreButton:YES];
                }
            } else {
                if (statusCode >= 300) {
                    flushSucc = NO;
                }
            }
        } else {
            messageDesc = @"\n【valid message】\n";
        }
        SAError(@"==========================================================================");
        if ([SALogger isLoggerEnabled]) {
//            @try {
//                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
//                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
//                NSString *logString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
//                SAError(@"%@ %@: %@", self,messageDesc,logString);
//            } @catch (NSException *exception) {
//                SAError(@"%@: %@", self, exception);
//            }
        }
        if (statusCode != 200) {
            SAError(@"%@ ret_code: %ld", self, statusCode);
            SAError(@"%@ ret_content: %@", self, urlResponseContent);
        }
        
        dispatch_semaphore_signal(flushSem);
    };
    NSURLRequest *request = [self buildRequestWithEvents:events HTTPMethod:@"POST"];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:handler];
    [task resume];
    
    dispatch_semaphore_wait(flushSem, DISPATCH_TIME_FOREVER);
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        do {
            SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
            NSCAssert(serverTrust != nil, @"ServerTrust is nil");
            if(nil == serverTrust){
                break; /* failed */
            }

            /**
             *  导入多张CA证书（Certification Authority，支持SSL证书以及自签名的CA），请替换掉你的证书名称
             */
            NSCAssert(self.certificateData != nil, @"certificateData is nil");
            if (!self.certificateData) {
                break; /* failed */
            }

            SecCertificateRef certificateRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)self.certificateData);
            NSCAssert(certificateRef != nil, @"certificateRef is nil");
            if(!certificateRef) {
                break; /* failed */
            }

            // 可以添加多张证书
            NSArray *certificates = @[(__bridge id)(certificateRef)];
            NSCAssert(certificates != nil, @"certificates is nil");
            if(!certificates) {
                break; /* failed */
            }

            // 将读取的证书设置为服务端帧数的根证书
            OSStatus status = SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)certificates);
            NSCAssert(errSecSuccess == status, @"SecTrustSetAnchorCertificates failed");
            if(status != errSecSuccess) {
                break; /* failed */
            }

            SecTrustResultType result = -1;
            // 通过本地导入的证书来验证服务器的证书是否可信
            status = SecTrustEvaluate(serverTrust, &result);
            if(status != errSecSuccess) {
                break; /* failed */
            }

            NSLog(@"stutas: %d",(int)status);
            NSLog(@"Result: %d", result);
            BOOL allowConnect = (result == kSecTrustResultUnspecified) || (result == kSecTrustResultProceed);
            if (allowConnect) {
                NSLog(@"success");
            } else {
                NSLog(@"error");
            }
            /* kSecTrustResultUnspecified and kSecTrustResultProceed are success */
            if(!allowConnect) {
                break; /* failed */
            }
#if 0
            /* Treat kSecTrustResultConfirm and kSecTrustResultRecoverableTrustFailure as success */
            /* since the user will likely tap-through to see the dancing bunnies */
            if(result == kSecTrustResultDeny || result == kSecTrustResultFatalTrustFailure || result == kSecTrustResultOtherError) {
                break; /* failed to trust cert (good in this case) */
            }
#endif
            // The only good exit point
            NSLog(@"信任该证书");

            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            return [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];

        } while(0);
    }

    // Bad dog
    NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, credential);
    return [challenge.sender cancelAuthenticationChallenge:challenge];
}

@end
