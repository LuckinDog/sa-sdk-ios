//
//  SAAuxiliaryToolManager.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/9/7.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import "SAAuxiliaryToolManager.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"
#import "SAAlertController.h"

@interface SAAuxiliaryToolManager()
@property (nonatomic, strong) SAVisualAutoTrackConnection *visualAutoTrackConnection;
@property (nonatomic, strong) SAHeatMapConnection *heatMapConnection;
@property (nonatomic, copy) NSString *postUrl;
@property (nonatomic, copy) NSString *featureCode;
@property (nonatomic, strong) NSURL *originalURL;
@end
@implementation SAAuxiliaryToolManager
+ (instancetype)sharedInstance {
    static SAAuxiliaryToolManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SAAuxiliaryToolManager alloc] init];
    });
    return sharedInstance;
}

- (BOOL)canHandleURL:(NSURL *)URL {
    return [self isVisualHeatMapURL:URL] || [self isVisualAutoTrackURL:URL] || [self isVisualDebugModeURL:URL];
}

- (BOOL)handleURL:(NSURL *)URL isWifi:(BOOL)isWifi {
    if ([self canHandleURL:URL] == NO) {
        return NO;
    }
    NSString *featureCode = nil;
    NSString *postURLStr = nil;
    [self featureCode:&featureCode postURL:&postURLStr URL:URL];
    if (featureCode != nil && postURLStr != nil) {
        [self showOpenDialogWithURL:URL featureCode:featureCode postURL:postURLStr isWifi:isWifi ];
        return YES;
    } else { //feature_code  url 参数错误
        [self showParameterError:@"ERROR" message:@"参数错误"];
        return NO;
    }
    return NO;
}

- (void)showOpenDialogWithURL:(NSURL *)URL featureCode:(NSString *)featureCode postURL:(NSString *)postURL isWifi:(BOOL)isWifi {
    self.featureCode = featureCode;
    self.postUrl = postURL;
    self.originalURL = URL;
    NSString *alertTitle = @"提示";
    NSString *alertMessage = [self alertMessageWithURL:URL isWifi:isWifi];
    
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:alertTitle message:alertMessage preferredStyle:SAAlertControllerStyleAlert];
    
    [alertController addActionWithTitle:@"取消" style:SAAlertActionStyleCancel handler:^(SAAlertAction * _Nonnull action) {
        [self.visualAutoTrackConnection close];
        [self.heatMapConnection close];
        self.visualAutoTrackConnection = nil;
        self.heatMapConnection = nil;
    }];
    
    [alertController addActionWithTitle:@"继续" style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
        SADebug(@"Confirmed to open HeatMap ...");
        // start
        if ([self isVisualHeatMapURL:URL]) {
            self.heatMapConnection = [[SAHeatMapConnection alloc] initWithURL:nil];
            [self.heatMapConnection startConnectionWithFeatureCode:featureCode url:postURL];
        } else if ([self isVisualAutoTrackURL:URL]) {
            self.visualAutoTrackConnection = [[SAVisualAutoTrackConnection alloc] initWithURL:nil];
            [self.visualAutoTrackConnection startConnectionWithFeatureCode:featureCode url:postURL];
        }
    }];
    
    [alertController show];
}

- (NSString *)alertMessageWithURL:(NSURL *)URL isWifi:(BOOL)isWifi {
    NSString *alertMessage = nil;
    if ([self isVisualHeatMapURL:URL]) {
        alertMessage = @"正在连接 APP 点击分析";
    } else if ([self isVisualAutoTrackURL:URL]) {
        alertMessage = @"正在连接 APP 自定义埋点";
    }
    if (isWifi ==NO && alertMessage != nil) {
        alertMessage = [alertMessage stringByAppendingString: @"，建议在 WiFi 环境下使用"];
    }
    return alertMessage;
}

- (BOOL)isVisualHeatMapURL:(NSURL *)url {
    return [url.host isEqualToString:@"heatmap"];
}

- (BOOL)isVisualAutoTrackURL:(NSURL *)url {
    return [url.host isEqualToString:@"appcircle"];
}

- (BOOL)isVisualDebugModeURL:(NSURL *)url {
     return [url.host isEqualToString:@"debugmode"];
}

- (void)featureCode:(NSString **)featureCode postURL:(NSString **)postURL URL:(NSURL *)url {
    @try {
        NSString *query = [url query];
        if (query != nil) {
            NSArray *subArray = [query componentsSeparatedByString:@"&"];
            NSMutableDictionary *tempDic = [[NSMutableDictionary alloc] init];
            if (subArray) {
                for (int j = 0 ; j < subArray.count; j++) {
                    //在通过=拆分键和值
                    NSArray *dicArray = [subArray[j] componentsSeparatedByString:@"="];
                    //给字典加入元素
                    [tempDic setObject:dicArray[1] forKey:dicArray[0]];
                }
                *featureCode = [tempDic objectForKey:@"feature_code"];
                *postURL = [tempDic objectForKey:@"url"];
            }
        }
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
}
- (void)showParameterError:(NSString *)alertTitle message:(NSString *)alertMessage {
        SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:alertTitle message:alertMessage preferredStyle:SAAlertControllerStyleAlert];
        [alertController addActionWithTitle:@"OK" style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
            
        }];
        
        [alertController show];

}
@end
