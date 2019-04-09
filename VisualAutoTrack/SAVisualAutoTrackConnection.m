//
//  SAVisualAutoTrackConnection.m,
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/9/4.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "SAVisualAutoTrackConnection.h"
#import "SAVisualAutoTrackMessage.h"
#import "SAVisualAutoTrackSnapshotMessage.h"
#import "SALogger.h"
#import "SensorsAnalyticsSDK.h"

@interface SAVisualAutoTrackConnection ()

@end

@implementation SAVisualAutoTrackConnection {
    BOOL _connected;

    NSURL *_url;
    NSDictionary *_typeToMessageClassMap;
    NSOperationQueue *_commandQueue;
    NSTimer *timer;
    id<SAVisualAutoTrackMessage> _designerMessage;
    NSString *_featureCode;
    NSString *_postUrl;
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _typeToMessageClassMap = @{
            SAVisualAutoTrackSnapshotRequestMessageType : [SAVisualAutoTrackSnapshotRequestMessage class],
        };
        _connected = NO;
        _useGzip = YES;
        _url = url;

        _commandQueue = [[NSOperationQueue alloc] init];
        _commandQueue.maxConcurrentOperationCount = 1;
        _commandQueue.suspended = YES;
    }

    return self;
}

- (void)close {
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
}

- (void)dealloc {
    [self close];
}

- (void)setSessionObject:(id)object forKey:(NSString *)key {
    NSParameterAssert(key != nil);
}

- (id)sessionObjectForKey:(NSString *)key {
    NSParameterAssert(key != nil);
    return key;
}

- (void)sendMessage:(id<SAVisualAutoTrackMessage>)message {
    if (_connected) {
        if (_featureCode == nil || _postUrl == nil) {
            return;
        }
        NSString *jsonString = [[NSString alloc] initWithData:[message JSONData:_useGzip featuerCode:_featureCode] encoding:NSUTF8StringEncoding];
        NSURL *URL = [NSURL URLWithString:_postUrl];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData* data, NSError *error) {
             NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
             NSString *urlResponseContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             if ([urlResponse statusCode] == 200) {
                 NSData *jsonData = [urlResponseContent dataUsingEncoding:NSUTF8StringEncoding];
                 NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                 int delay = [[dict objectForKey:@"delay"] intValue];
                 if (delay < 0) {
                     [self close];
                 }
             }
         }];

    } else {
        SADebug(@"Not sending message as we are not connected: %@", [message debugDescription]);
    }
}

- (id <SAVisualAutoTrackMessage>)designerMessageForMessage:(id)message {
    NSParameterAssert([message isKindOfClass:[NSString class]] || [message isKindOfClass:[NSData class]]);

    id <SAVisualAutoTrackMessage> designerMessage = nil;

    NSData *jsonData = [message isKindOfClass:[NSString class]] ? [(NSString *)message dataUsingEncoding:NSUTF8StringEncoding] : message;
   // SADebug(@"%@ VTrack received message: %@", self, [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *messageDictionary = (NSDictionary *)jsonObject;
        NSString *type = messageDictionary[@"type"];
        NSDictionary *payload = messageDictionary[@"payload"];

        designerMessage = [_typeToMessageClassMap[type] messageWithType:type payload:payload];
    } else {
        SAError(@"Badly formed socket message expected JSON dictionary: %@", error);
    }

    return designerMessage;
}

#pragma mark -  Methods

- (void)startVisualAutoTrackTimer:(id)message featureCode:(NSString *)featureCode postURL:(NSString *)postURL {
    _featureCode = featureCode;
    _postUrl = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)postURL, CFSTR(""),  CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    _designerMessage = [self designerMessageForMessage:message];

    if (timer) {
        [timer invalidate];
        timer = nil;
    }

    timer = [NSTimer scheduledTimerWithTimeInterval:1
                                             target:self
                                           selector:@selector(handleMessage)
                                           userInfo:nil
                                            repeats:YES];
}

- (void)handleMessage {
    if (_designerMessage) {
        NSOperation *commandOperation = [_designerMessage responseCommandWithConnection:self];
        if (commandOperation) {
            [_commandQueue addOperation:commandOperation];
        }
    }
}

- (void)startConnectionWithFeatureCode:(NSString *)featureCode url:(NSString *)urlStr {
    NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[SensorsAnalyticsSDK class]] pathForResource:@"SensorsAnalyticsSDK" ofType:@"bundle"]];
    //文件路径
    NSString *jsonPath = [sensorsBundle pathForResource:@"sa_visual_autoTrack_path.json" ofType:nil];
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    _commandQueue.suspended = NO;
    if (!self->_connected) {
        self->_connected = YES;
        [self startVisualAutoTrackTimer:jsonString featureCode:featureCode postURL:urlStr];
    } else {
        [self startVisualAutoTrackTimer:jsonString featureCode:featureCode postURL:urlStr];
    }
}

@end

