//
//  SensorsAnalyticsNetwork.m
//  SensorsAnalyticsSDK
//
//  Created by MC on 2019/3/8.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
//

#import "SensorsAnalyticsNetwork.h"

@interface SensorsAnalyticsNetwork () <NSURLSessionDelegate>

@property (nonatomic, strong) NSURL *serverURL;

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@property (nonatomic, strong) NSURLSession *session;

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

- (void)flushEvents:(NSArray<NSString *> *)events {
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:self.serverURL];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req];
    [task resume];
}

- (void)flushEvents:(NSArray<NSString *> *)events completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:self.serverURL];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req completionHandler:completionHandler];
    [task resume];
}


- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        do {
            SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
            NSCAssert(serverTrust != nil, @"ServerTrust is nil");
            if(nil == serverTrust)
                break; /* failed */

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
