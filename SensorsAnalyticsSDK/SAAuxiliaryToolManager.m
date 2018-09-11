//
//  SAAuxiliaryToolManager.m
//  SensorsAnalyticsSDK
//
//  Created by ziven.mac on 2018/9/7.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import "SAAuxiliaryToolManager.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"
@interface SAAuxiliaryToolManager()<UIAlertViewDelegate>
@property (nonatomic, strong) SAAppCircleConnection *appCircleConnection;
@property (nonatomic, strong) SAHeatMapConnection *heatMapConnection;
@property (nonatomic,copy) NSString *postUrl;
@property (nonatomic,copy) NSString *featureCode;
@property (nonatomic,strong) NSURL *originalURL;
@end
@implementation SAAuxiliaryToolManager
+(instancetype)sharedInstance {
    static SAAuxiliaryToolManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SAAuxiliaryToolManager alloc] init];
    });
    return sharedInstance;
}

-(BOOL)canOpenURL:(NSURL *)URL {
    return [self isHeatMapURL:URL] || [self isAppCircleURL:URL];
}

- (BOOL)openURL:(NSURL *)URL  isWifi:(BOOL)isWifi {
    if ([self canOpenURL:URL] == NO) {
        return NO;
    }
    NSString *featureCode = nil;
    NSString *postURLStr = nil;
    [self getFeatureCode:&featureCode andPostURL:&postURLStr WithURL:URL];
    if (featureCode != nil && postURLStr != nil) {
        [self showOpenDialogWithURL:URL featureCode:featureCode postURL:postURLStr isWifi:isWifi ];
        return YES;
    }else { //feature_code  url 参数错误
        [self showParameterError:@"ERROR" message:@"参数错误"];
        return NO;
    }
    return NO;
}

- (void)showOpenDialogWithURL:(NSURL*)URL featureCode:(NSString *)featureCode postURL:(NSString *)postURL isWifi:(BOOL)isWifi {
    self.featureCode = featureCode;
    self.postUrl = postURL;
    self.originalURL = URL;
    NSString *alertTitle = @"提示";
    NSString *alertMessage = [self alertMessageWithURL:URL isWifi:isWifi];
    if (@available(iOS 8.0, *)) {
        UIWindow *mainWindow = UIApplication.sharedApplication.keyWindow;
        if (mainWindow == nil) {
            mainWindow = [[UIApplication sharedApplication] delegate].window;
        }
        if (mainWindow == nil) {
            return;
        }
        
        UIAlertController *connectAlert = [UIAlertController
                                           alertControllerWithTitle:alertTitle
                                           message:alertMessage
                                           preferredStyle:UIAlertControllerStyleAlert];
        
        [connectAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            SADebug(@"Canceled to open HeatMap ...");
            //do nothing
            [self.appCircleConnection close];
            [self.heatMapConnection close];
            self.appCircleConnection = nil;
            self.heatMapConnection = nil;
        }]];
        
        [connectAlert addAction:[UIAlertAction actionWithTitle:@"继续" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            SADebug(@"Confirmed to open HeatMap ...");
            // start
            if ([self isHeatMapURL:URL]) {
                self.heatMapConnection = [[SAHeatMapConnection alloc]initWithURL:nil];
                if (self.heatMapConnection) {
                    [self.heatMapConnection startConnectionWithFeatureCode:featureCode url:postURL];
                }
            }else if ([self isAppCircleURL:URL]) {
                 self.appCircleConnection = [[SAAppCircleConnection alloc] initWithURL:nil];
                if (self.appCircleConnection) {
                    [self.appCircleConnection startConnectionWithFeatureCode:featureCode url:postURL];
                }
            }
        }]];
        
        UIViewController *viewController = mainWindow.rootViewController;
        while (viewController.presentedViewController) {
            viewController = viewController.presentedViewController;
        }
        [viewController presentViewController:connectAlert animated:YES completion:nil];
    } else {
        UIAlertView *connectAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"继续", nil];
        [connectAlert show];
    }
}

-(NSString *)alertMessageWithURL:(NSURL *)URL isWifi:(BOOL)isWifi {
    NSString *alertMessage = nil;
    if ([self isHeatMapURL:URL]) {
        alertMessage = @"正在连接 APP 点击分析";
    }else if ([self isAppCircleURL:URL]) {
        alertMessage = @"正在连接 APP 自定义埋点";
    }
    if (isWifi ==NO && alertMessage != nil) {
        alertMessage = [alertMessage stringByAppendingString: @"，建议在 WiFi 环境下使用"];
    }
    return alertMessage;
}

-(BOOL)isHeatMapURL:(NSURL *)URL {
    return [URL.host isEqualToString:@"heatmap"];
}

-(BOOL)isAppCircleURL:(NSURL *)URL {
    return [URL.host isEqualToString:@"appcircle"];
}


-(void)getFeatureCode:(NSString **)featureCode andPostURL:(NSString **)postURL WithURL:(NSURL *)url {
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
-(void)showParameterError:(NSString *)alertTitle message:(NSString *)alertMessage {
    if (@available(iOS 8.0, *)) {
        UIWindow *mainWindow = UIApplication.sharedApplication.keyWindow;
        if (mainWindow == nil) {
            mainWindow = [[UIApplication sharedApplication] delegate].window;
        }
        if (mainWindow == nil) {
            return;
        }
        
        UIAlertController *connectAlert = [UIAlertController
                                           alertControllerWithTitle:alertTitle
                                           message:alertMessage
                                           preferredStyle:UIAlertControllerStyleAlert];
        
    
        [connectAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
           
        }]];
        
        UIViewController *viewController = mainWindow.rootViewController;
        while (viewController.presentedViewController) {
            viewController = viewController.presentedViewController;
        }
        [viewController presentViewController:connectAlert animated:YES completion:nil];
    } else {
        UIAlertView *connectAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [connectAlert show];
    }
}

#pragma mark -UIAlertViewDelagete
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        SADebug(@"Canceled to open AppCircle ...");
        [self.appCircleConnection close];
        [self.heatMapConnection close];
        self.appCircleConnection = nil;
        self.heatMapConnection = nil;
    } else {
        SADebug(@"Confirmed to open AppCircle ...");
        //start
        if ([self isHeatMapURL:self.originalURL]) {
            self.heatMapConnection = [[SAHeatMapConnection alloc]initWithURL:nil];
            if (self.heatMapConnection) {
                [self.heatMapConnection startConnectionWithFeatureCode:self.featureCode url:self.postUrl];
            }
        }else if ([self isAppCircleURL:self.originalURL]) {
            self.appCircleConnection = [[SAAppCircleConnection alloc] initWithURL:nil];
            if (self.appCircleConnection) {
                [self.appCircleConnection startConnectionWithFeatureCode:self.featureCode url:self.postUrl];
            }
        }
    }
}
@end
