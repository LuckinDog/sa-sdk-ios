//  SensorsAnalyticsSDK.m
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/1.
//  Copyright (c) 2015年 SensorsData. All rights reserved.

#import <objc/runtime.h>
#include <sys/sysctl.h>
#include <stdlib.h>

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>

#import "JSONUtil.h"
#import "SAGzipUtility.h"
#import "MessageQueueBySqlite.h"
#import "SALogger.h"
#import "SAReachability.h"
#import "SensorsAnalyticsSDK.h"
#import "JSONUtil.h"
#import "NSString+HashCode.h"
#import "SensorsAnalyticsExceptionHandler.h"
#import "SAServerUrl.h"
#import "SAAppExtensionDataManager.h"
#import "SAKeyChainItemWrapper.h"
#import "SASDKRemoteConfig.h"
#import "SADeviceOrientationManager.h"
#import "SALocationManager.h"
#import "NSThread+SAHelpers.h"
#define VERSION @"1.10.6"
#define PROPERTY_LENGTH_LIMITATION 8191

// 自动追踪相关事件及属性
// App 启动或激活
static NSString* const APP_START_EVENT = @"$AppStart";
// App 退出或进入后台
static NSString* const APP_END_EVENT = @"$AppEnd";
// App 首次启动
static NSString* const APP_FIRST_START_PROPERTY = @"$is_first_time";
// App 是否从后台恢复
static NSString* const RESUME_FROM_BACKGROUND_PROPERTY = @"$resume_from_background";
// App 浏览页面名称
static NSString* const SCREEN_NAME_PROPERTY = @"$screen_name";
// App 浏览页面 Url
static NSString* const SCREEN_URL_PROPERTY = @"$url";
// App 浏览页面 Referrer Url
static NSString* const SCREEN_REFERRER_URL_PROPERTY = @"$referrer";
//中国运营商 mcc 标识
static NSString* const CARRIER_CHINA_MCC = @"460";

static SensorsAnalyticsSDK *sharedInstance = nil;

@interface SensorsAnalyticsSDK()

// 在内部，重新声明成可读写的
@property (atomic, strong) SensorsAnalyticsPeople *people;

@property (atomic, copy) NSString *serverURL;

@property (atomic, copy) NSString *distinctId;
@property (atomic, copy) NSString *originalId;
@property (atomic, copy) NSString *loginId;
@property (atomic, copy) NSString *firstDay;
@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (atomic, strong) NSDictionary *automaticProperties;
@property (atomic, strong) NSDictionary *superProperties;
@property (nonatomic, strong) NSMutableDictionary *trackTimer;

@property (nonatomic, strong) NSPredicate *regexTestName;

@property (atomic, strong) MessageQueueBySqlite *messageQueue;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) SASDKRemoteConfig *remoteConfig;

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
@property (nonatomic, strong) SADeviceOrientationManager *deviceOrientationManager;
@property (nonatomic, strong) SADeviceOrientationConfig *deviceOrientationConfig;
#endif

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
@property (nonatomic, strong) SALocationManager *locationManager;
@property (nonatomic, strong) SAGPSLocationConfig *locationConfig;
#endif

@property (nonatomic, copy) void(^reqConfigBlock)(BOOL success , NSDictionary *configDict);
@property (nonatomic, assign) NSUInteger pullSDKConfigurationRetryMaxCount;

@property (nonatomic,copy) NSDictionary<NSString *,id> *(^dynamicSuperProperties)(void);

@end

@implementation SensorsAnalyticsSDK {
    SensorsAnalyticsDebugMode _debugMode;
    UInt64 _flushBulkSize;
    UInt64 _flushInterval;
    UInt64 _maxCacheSize;
    NSDateFormatter *_dateFormatter;
    BOOL _autoTrack;                    // 自动采集事件
    BOOL _appRelaunched;                // App 从后台恢复
    BOOL _showDebugAlertView;
    UInt8 _debugAlertViewHasShownNumber;
    NSDictionary * _launchOptions;
    UIApplicationState _applicationState;
    BOOL _applicationWillResignActive;
	SensorsAnalyticsAutoTrackEventType _autoTrackEventType;
    SensorsAnalyticsNetworkType _networkTypePolicy;
    NSString *_deviceModel;
    NSString *_osVersion;
    NSString *_userAgent;
    NSString *_originServerUrl;
    NSString *_cookie;
}

#pragma mark - Initialization
+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(NSString *)serverURL
                                        andDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    return [SensorsAnalyticsSDK sharedInstanceWithServerURL:serverURL
            andLaunchOptions:nil andDebugMode:debugMode];
}

+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(NSString *)serverURL
                                        andLaunchOptions:(NSDictionary *)launchOptions
                                        andDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc] initWithServerURL:serverURL
                                         andLaunchOptions:launchOptions
                                             andDebugMode:debugMode];
    });
    return sharedInstance;
}

+ (SensorsAnalyticsSDK *)sharedInstance {
    if (sharedInstance.remoteConfig.disableSDK) {
        return nil;
    }
    return sharedInstance;
}

+ (UInt64)getCurrentTime {
    UInt64 time = [[NSDate date] timeIntervalSince1970] * 1000;
    return time;
}

+ (UInt64)getSystemUpTime {
    UInt64 time = NSProcessInfo.processInfo.systemUptime * 1000;
    return time;
}

+ (NSString *)getUniqueHardwareId:(BOOL *)isReal {
    NSString *distinctId = NULL;

    // 宏 SENSORS_ANALYTICS_IDFA 定义时，优先使用IDFA
#if defined(SENSORS_ANALYTICS_IDFA)
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        distinctId = [uuid UUIDString];
        // 在 iOS 10.0 以后，当用户开启限制广告跟踪，advertisingIdentifier 的值将是全零
        // 00000000-0000-0000-0000-000000000000
        if (distinctId && ![distinctId hasPrefix:@"00000000"]) {
            *isReal = YES;
        } else{
            distinctId = NULL;
        }
    }
#endif
    
    // 没有IDFA，则使用IDFV
    if (!distinctId && NSClassFromString(@"UIDevice")) {
        distinctId = [[UIDevice currentDevice].identifierForVendor UUIDString];
        *isReal = YES;
    }
    
    // 没有IDFV，则使用UUID
    if (!distinctId) {
        SADebug(@"%@ error getting device identifier: falling back to uuid", self);
        distinctId = [[NSUUID UUID] UUIDString];
        *isReal = NO;
    }
    
    return distinctId;
}

+(NSString *)getUserAgent {
    //1, 尝试从 SAUserAgent 缓存读取，
    __block  NSString *currentUA = [[NSUserDefaults standardUserDefaults] objectForKey:@"SAUserAgent"];
    if (currentUA  == nil)  {
        //2,从 webview 执行 JS 获取 UA
        if ([NSThread isMainThread]) {
            UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
            currentUA = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
            [[NSUserDefaults standardUserDefaults] setObject:currentUA forKey:@"SAUserAgent"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
                currentUA = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
                [[NSUserDefaults standardUserDefaults] setObject:currentUA forKey:@"SAUserAgent"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            });
        }
    }
    return currentUA;
}

- (instancetype)initWithServerURL:(NSString *)serverURL
                    andLaunchOptions:(NSDictionary *)launchOptions
                     andDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    @try {
        if (self = [self init]) {
            _autoTrackEventType = SensorsAnalyticsEventTypeNone;
            _networkTypePolicy = SensorsAnalyticsNetworkType3G | SensorsAnalyticsNetworkType4G | SensorsAnalyticsNetworkTypeWIFI;

            _launchOptions = launchOptions;
            if ([[NSThread currentThread] isMainThread]) {
                _applicationState = UIApplication.sharedApplication.applicationState;
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _applicationState = UIApplication.sharedApplication.applicationState;
                });
            }

            self.people = [[SensorsAnalyticsPeople alloc] initWithSDK:self];

    
            _debugMode = debugMode;
            [self setServerUrl:serverURL];
            [self enableLog];
            
            _flushInterval = 15 * 1000;
            _flushBulkSize = 100;
            _maxCacheSize = 10000;
            _autoTrack = NO;
            _appRelaunched = NO;
            _showDebugAlertView = YES;
            _debugAlertViewHasShownNumber = 0;
            _applicationWillResignActive = NO;
            _pullSDKConfigurationRetryMaxCount = 3;// SDK 开启关闭功能接口最大重试次数
            _remoteConfig = [[SASDKRemoteConfig alloc]init];
            NSDictionary *sdkConfig = [[NSUserDefaults standardUserDefaults] objectForKey:@"SASDKConfig"];
            [self setSDKWithRemoteConfigDict:sdkConfig];

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
            _deviceOrientationConfig = [[SADeviceOrientationConfig alloc]init];
#endif

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
            _locationConfig = [[SAGPSLocationConfig alloc]init];
#endif
    
            _dateFormatter = [[NSDateFormatter alloc] init];
            [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];

            self.flushBeforeEnterBackground = YES;

            self.messageQueue = [[MessageQueueBySqlite alloc] initWithFilePath:[self filePathForData:@"message-v2"]];
            if (self.messageQueue == nil) {
                SADebug(@"SqliteException: init Message Queue in Sqlite fail");
            }

            // 取上一次进程退出时保存的distinctId、loginId、superProperties
            [self unarchive];

            if (self.firstDay == nil) {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd"];
                self.firstDay = [dateFormatter stringFromDate:[NSDate date]];
                [self archiveFirstDay];
            }

            self.automaticProperties = [self collectAutomaticProperties];
            self.trackTimer = [NSMutableDictionary dictionary];

            NSString *namePattern = @"^((?!^distinct_id$|^original_id$|^time$|^event$|^properties$|^id$|^first_id$|^second_id$|^users$|^events$|^event$|^user_id$|^date$|^datetime$)[a-zA-Z_$][a-zA-Z\\d_$]{0,99})$";
            self.regexTestName = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", namePattern];

            NSString *label = [NSString stringWithFormat:@"com.sensorsdata.%@.%p", @"test", self];
            self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);

            [self setUpListeners];

            // 渠道追踪请求，需要从 UserAgent 中解析 OS 信息用于模糊匹配
            _userAgent = [self.class getUserAgent];
            
            // XXX: App Active 的时候会启动计时器，此处不需要启动
            //        [self startFlushTimer];
            NSString *logMessage = nil;
            logMessage = [NSString stringWithFormat:@"%@ initialized the instance of Sensors Analytics SDK with server url '%@', debugMode: '%@'",
                              self, serverURL, [self debugModeToString:debugMode]];
            SALog(@"%@", logMessage);
            
            //打开debug模式，弹出提示
#ifndef SENSORS_ANALYTICS_DISABLE_DEBUG_WARNING
            if (_debugMode != SensorsAnalyticsDebugOff) {
                NSString *alertMessage = nil;
                if (_debugMode == SensorsAnalyticsDebugOnly) {
                    alertMessage = @"现在您打开了'DEBUG_ONLY'模式，此模式下只校验数据但不导入数据，数据出错时会以提示框的方式提示开发者，请上线前一定关闭。";
                } else if (_debugMode == SensorsAnalyticsDebugAndTrack) {
                    alertMessage = @"现在您打开了'DEBUG_AND_TRACK'模式，此模式下会校验数据并且导入数据，数据出错时会以提示框的方式提示开发者，请上线前一定关闭。";
                }
                [self showDebugModeWarning:alertMessage withNoMoreButton:NO];
            }
#endif
        }
    } @catch(NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
    return self;
}

- (BOOL)isLaunchedPassively {
    @try {
        //远程通知启动
        NSDictionary *remoteNotification = _launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
        if (remoteNotification) {
            if (_applicationState == UIApplicationStateBackground) {
                return YES ;
            }
        }

        //位置变动启动
        NSDictionary *location = _launchOptions[UIApplicationLaunchOptionsLocationKey];
        if (location) {
            if (_applicationState == UIApplicationStateBackground) {
                return YES ;
            }
        }
    } @catch(NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }

    return NO;
}

- (NSDictionary *)getPresetProperties {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    @try {
        id app_version = [_automaticProperties objectForKey:@"$app_version"];
        if (app_version) {
            [properties setValue:app_version forKey:@"$app_version"];
        }
        [properties setValue:[_automaticProperties objectForKey:@"$lib"] forKey:@"$lib"];
        [properties setValue:[_automaticProperties objectForKey:@"$lib_version"] forKey:@"$lib_version"];
        [properties setValue:@"Apple" forKey:@"$manufacturer"];
        [properties setValue:_deviceModel forKey:@"$model"];
        [properties setValue:@"iOS" forKey:@"$os"];
        [properties setValue:_osVersion forKey:@"$os_version"];
        [properties setValue:[_automaticProperties objectForKey:@"$screen_height"] forKey:@"$screen_height"];
        [properties setValue:[_automaticProperties objectForKey:@"$screen_width"] forKey:@"$screen_width"];
        NSString *networkType = [SensorsAnalyticsSDK getNetWorkStates];
        [properties setObject:networkType forKey:@"$network_type"];
        if ([networkType isEqualToString:@"WIFI"]) {
            [properties setObject:@YES forKey:@"$wifi"];
        } else {
            [properties setObject:@NO forKey:@"$wifi"];
        }
        [properties setValue:[_automaticProperties objectForKey:@"$carrier"] forKey:@"$carrier"];
        if ([self isFirstDay]) {
            [properties setObject:@YES forKey:@"$is_first_day"];
        } else {
            [properties setObject:@NO forKey:@"$is_first_day"];
        }
        [properties setValue:[_automaticProperties objectForKey:@"$device_id"] forKey:@"$device_id"];
    } @catch(NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
    return [properties copy];
}

- (void)setServerUrl:(NSString *)serverUrl {
    _originServerUrl = serverUrl;
    if (serverUrl == nil || [serverUrl length] == 0 || _debugMode == SensorsAnalyticsDebugOff) {
        _serverURL = serverUrl;
    } else {
        // 将 Server URI Path 替换成 Debug 模式的 '/debug'
        NSURL *url = [[[NSURL URLWithString:serverUrl] URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"debug"];
        _serverURL = [url absoluteString];
    }
}

- (void)disableDebugMode {
    _debugMode = SensorsAnalyticsDebugOff;
    _serverURL = _originServerUrl;
    [self enableLog:NO];
}

- (NSString *)debugModeToString:(SensorsAnalyticsDebugMode)debugMode {
    NSString *modeStr = nil;
    switch (debugMode) {
        case SensorsAnalyticsDebugOff:
            modeStr = @"DebugOff";
            break;
        case SensorsAnalyticsDebugAndTrack:
            modeStr = @"DebugAndTrack";
            break;
        case SensorsAnalyticsDebugOnly:
            modeStr = @"DebugOnly";
            break;
        default:
            modeStr = @"Unknown";
            break;
    }
    return modeStr;
}

- (void)showDebugModeWarning:(NSString *)message withNoMoreButton:(BOOL)showNoMore {
#ifndef SENSORS_ANALYTICS_DISABLE_DEBUG_WARNING
    if (_debugMode == SensorsAnalyticsDebugOff) {
        return;
    }

    if (!_showDebugAlertView) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (self->_debugAlertViewHasShownNumber >= 3) {
                return;
            }
            self->_debugAlertViewHasShownNumber += 1;
            NSString *alertTitle = @"SensorsData 重要提示";
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
                UIAlertController *connectAlert = [UIAlertController
                                                   alertControllerWithTitle:alertTitle
                                                   message:message
                                                   preferredStyle:UIAlertControllerStyleAlert];

                UIWindow *alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                [connectAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    alertWindow.hidden = YES;
                    self->_debugAlertViewHasShownNumber -= 1;
                }]];
                if (showNoMore) {
                    [connectAlert addAction:[UIAlertAction actionWithTitle:@"不再显示" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        alertWindow.hidden = YES;
                        self->_showDebugAlertView = NO;
                    }]];
                }

                alertWindow.rootViewController = [[UIViewController alloc] init];
                alertWindow.windowLevel = UIWindowLevelAlert + 1;
                [alertWindow makeKeyAndVisible];
                [alertWindow.rootViewController presentViewController:connectAlert animated:YES completion:nil];
            } else {
                UIAlertView *connectAlert = nil;
                if (showNoMore) {
                    connectAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:message delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"不再显示",nil, nil];
                } else {
                    connectAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:message delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                }
                [connectAlert show];
            }
        } @catch (NSException *exception) {
        } @finally {
        }
    });
#endif
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        _showDebugAlertView = NO;
    } else if (buttonIndex == 0) {
        _debugAlertViewHasShownNumber -= 1;
    }
}

- (BOOL)isFirstDay {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *current = [dateFormatter stringFromDate:[NSDate date]];

    return [[self firstDay] isEqualToString:current];
}

- (void)setFlushNetworkPolicy:(SensorsAnalyticsNetworkType)networkType {
    @synchronized (self) {
        _networkTypePolicy = networkType;
    }
}

- (SensorsAnalyticsNetworkType)toNetworkType:(NSString *)networkType {
    if ([@"NULL" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkTypeALL;
    } else if ([@"WIFI" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkTypeWIFI;
    } else if ([@"2G" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkType2G;
    }   else if ([@"3G" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkType3G;
    }   else if ([@"4G" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkType4G;
    }
    return SensorsAnalyticsNetworkTypeNONE;
}

- (UIViewController *)currentViewController {
    __block UIViewController *currentVC = nil;
    if ([NSThread isMainThread]) {
        @try {
            UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
            if (rootViewController != nil) {
                currentVC = [self getCurrentVCFrom:rootViewController];
            }
        } @catch (NSException *exception) {
            SAError(@"%@ error: %@", self, exception);
        }
        return currentVC;
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            @try {
                UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
                if (rootViewController != nil) {
                    currentVC = [self getCurrentVCFrom:rootViewController];
                }
            } @catch (NSException *exception) {
                SAError(@"%@ error: %@", self, exception);
            }
        });
        return currentVC;
    }
}

- (UIViewController *)getCurrentVCFrom:(UIViewController *)rootVC {
    @try {
        UIViewController *currentVC;
        if ([rootVC presentedViewController]) {
            // 视图是被presented出来的
            rootVC = [self getCurrentVCFrom:rootVC.presentedViewController];
        }
        
        if ([rootVC isKindOfClass:[UITabBarController class]]) {
            // 根视图为UITabBarController
            currentVC = [self getCurrentVCFrom:[(UITabBarController *)rootVC selectedViewController]];
        } else if ([rootVC isKindOfClass:[UINavigationController class]]){
            // 根视图为UINavigationController
            currentVC = [self getCurrentVCFrom:[(UINavigationController *)rootVC visibleViewController]];
        } else {
            // 根视图为非导航类
            if ([rootVC respondsToSelector:NSSelectorFromString(@"contentViewController")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                UIViewController *tempViewController = [rootVC performSelector:NSSelectorFromString(@"contentViewController")];
#pragma clang diagnostic pop
                if (tempViewController) {
                    currentVC = [self getCurrentVCFrom:tempViewController];
                }
            } else {
                currentVC = rootVC;
            }
        }
        
        return currentVC;
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

- (void)trackFromH5WithEvent:(NSString *)eventInfo enableVerify:(BOOL)enableVerify {
    dispatch_async(self.serialQueue, ^{
        @try {
            if (eventInfo == nil) {
                return;
            }

            NSData *jsonData = [eventInfo dataUsingEncoding:NSUTF8StringEncoding];
            NSError *err;
            NSMutableDictionary *eventDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                             options:NSJSONReadingMutableContainers
                                                                               error:&err];
            if(err) {
                return;
            }

            if (!eventDict) {
                return;
            }

            if (enableVerify) {
                NSString *serverUrl = [eventDict valueForKey:@"server_url"];
                if (serverUrl != nil) {
                    SAServerUrl *h5ServerUrl = [[SAServerUrl alloc] initWithUrl:serverUrl];
                    SAServerUrl *appServerUrl = [[SAServerUrl alloc] initWithUrl:_serverURL];
                    if (![appServerUrl check:h5ServerUrl]) {
                        return;
                    }
                } else {
                    //防止 H5 集成的 JS SDK 版本太老，没有发 server_url
                    return;
                }
            }

            NSString *type = [eventDict valueForKey:@"type"];
            NSString *bestId;
            if ([self loginId] != nil) {
                bestId = [self loginId];
            } else{
                bestId = [self distinctId];
            }

            if (bestId == nil) {
                [self resetAnonymousId];
                bestId = [self anonymousId];
            }

            [eventDict setValue:@([[self class] getCurrentTime]) forKey:@"time"];

            if([type isEqualToString:@"track_signup"]){
                [eventDict setValue:bestId forKey:@"original_id"];
            } else {
                [eventDict setValue:bestId forKey:@"distinct_id"];
            }
            [eventDict setValue:@(arc4random()) forKey:@"_track_id"];

            NSDictionary *libDict = [eventDict objectForKey:@"lib"];
            id app_version = [_automaticProperties objectForKey:@"$app_version"];
            if (app_version) {
                [libDict setValue:app_version forKey:@"$app_version"];
            }

            //update lib $app_version from super properties
            app_version = [_superProperties objectForKey:@"$app_version"];
            if (app_version) {
                [libDict setValue:app_version forKey:@"$app_version"];
            }

            NSMutableDictionary *automaticPropertiesCopy = [NSMutableDictionary dictionaryWithDictionary:_automaticProperties];
            [automaticPropertiesCopy removeObjectForKey:@"$lib"];
            [automaticPropertiesCopy removeObjectForKey:@"$lib_version"];

            NSMutableDictionary *propertiesDict = [eventDict objectForKey:@"properties"];
            if([type isEqualToString:@"track"] || [type isEqualToString:@"track_signup"]){
                [propertiesDict addEntriesFromDictionary:automaticPropertiesCopy];
                [propertiesDict addEntriesFromDictionary:_superProperties];

                // 每次 track 时手机网络状态
                NSString *networkType = [SensorsAnalyticsSDK getNetWorkStates];
                [propertiesDict setObject:networkType forKey:@"$network_type"];
                if ([networkType isEqualToString:@"WIFI"]) {
                    [propertiesDict setObject:@YES forKey:@"$wifi"];
                } else {
                    [propertiesDict setObject:@NO forKey:@"$wifi"];
                }

                //  是否首日访问
                if([type isEqualToString:@"track"]) {
                    if ([self isFirstDay]) {
                        [propertiesDict setObject:@YES forKey:@"$is_first_day"];
                    } else {
                        [propertiesDict setObject:@NO forKey:@"$is_first_day"];
                    }
                }

                [propertiesDict removeObjectForKey:@"$is_first_time"];
                [propertiesDict removeObjectForKey:@"_nocache"];
            }

            [eventDict removeObjectForKey:@"_nocache"];
            [eventDict removeObjectForKey:@"server_url"];

            // $project & $token
            NSString *project = [propertiesDict objectForKey:@"$project"];
            NSString *token = [propertiesDict objectForKey:@"$token"];
            if (project) {
                [propertiesDict removeObjectForKey:@"$project"];
                [eventDict setValue:project forKey:@"project"];
            }
            if (token) {
                [propertiesDict removeObjectForKey:@"$token"];
                [eventDict setValue:token forKey:@"token"];
            }

            SALog(@"\n【track event from H5】:\n%@", eventDict);

            if([type isEqualToString:@"track_signup"]) {
                NSString *newLoginId = [eventDict objectForKey:@"distinct_id"];
                if (![newLoginId isEqualToString:[self loginId]]) {
                    self.loginId = newLoginId;
                    [self archiveLoginId];
                    if (![newLoginId isEqualToString:[self distinctId]]) {
                        self.originalId = [self distinctId];
                        [self enqueueWithType:type andEvent:[eventDict copy]];
                    }
                }
            } else {
                [self enqueueWithType:type andEvent:[eventDict copy]];
            }
        } @catch (NSException *exception) {
            SAError(@"%@: %@", self, exception);
        }
    });
}

- (void)trackFromH5WithEvent:(NSString *)eventInfo {
    [self trackFromH5WithEvent:eventInfo enableVerify:NO];
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request {
    return [self showUpWebView:webView WithRequest:request andProperties:nil];
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request enableVerify:(BOOL)enableVerify {
    return [self showUpWebView:webView WithRequest:request andProperties:nil enableVerify:enableVerify];
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request andProperties:(NSDictionary *)propertyDict enableVerify:(BOOL)enableVerify {
    @try {
        SADebug(@"showUpWebView");
        if (webView == nil) {
            SADebug(@"showUpWebView == nil");
            return NO;
        }
        
        if (request == nil) {
            SADebug(@"request == nil");
            return NO;
        }
        
        JSONUtil *_jsonUtil = [[JSONUtil alloc] init];
        
        NSDictionary *bridgeCallbackInfo = [self webViewJavascriptBridgeCallbackInfo];
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        if (bridgeCallbackInfo) {
            [properties addEntriesFromDictionary:bridgeCallbackInfo];
        }
        if (propertyDict) {
            [properties addEntriesFromDictionary:propertyDict];
        }
        NSData* jsonData = [_jsonUtil JSONSerializeObject:properties];
        NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        NSString *scheme = @"sensorsanalytics://getAppInfo";
        NSString *js = [NSString stringWithFormat:@"sensorsdata_app_js_bridge_call_js('%@')", jsonString];
        
        NSString *trackEventScheme = @"sensorsanalytics://trackEvent";
        
        //判断系统是否支持WKWebView
        Class wkWebViewClass = NSClassFromString(@"WKWebView");
        
        NSString *urlstr = request.URL.absoluteString;
        if (urlstr == nil) {
            return NO;
        }
        NSArray *urlArray = [urlstr componentsSeparatedByString:@"?"];
        if (urlArray == nil) {
            return NO;
        }
        //解析参数
        NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc] init];
        //判读是否有参数
        if (urlArray.count > 1) {
            //这里解析参数,将参数放入字典中
            NSArray *paramsArray = [urlArray[1] componentsSeparatedByString:@"&"];
            for (NSString *param in paramsArray) {
                NSArray *keyValue = [param componentsSeparatedByString:@"="];
                if (keyValue.count == 2) {
                    [paramsDic setObject:keyValue[1] forKey:keyValue[0]];
                }
            }
        }
        
        if ([webView isKindOfClass:[UIWebView class]] == YES) {//UIWebView
            SADebug(@"showUpWebView: UIWebView");
            if ([urlstr rangeOfString:scheme].location != NSNotFound) {
                [webView stringByEvaluatingJavaScriptFromString:js];
                return YES;
            } else if ([urlstr rangeOfString:trackEventScheme].location != NSNotFound) {
                if ([paramsDic count] > 0) {
                    NSString *eventInfo = [paramsDic objectForKey:@"event"];
                    if (eventInfo != nil) {
                        NSString* encodedString = [eventInfo stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        [self trackFromH5WithEvent:encodedString enableVerify:enableVerify];
                    }
                }
                return YES;
            }
            return NO;
        } else if(wkWebViewClass && [webView isKindOfClass:wkWebViewClass] == YES) {//WKWebView
            SADebug(@"showUpWebView: WKWebView");
            if ([urlstr rangeOfString:scheme].location != NSNotFound) {
                typedef void(^Myblock)(id,NSError *);
                Myblock myBlock = ^(id _Nullable response, NSError * _Nullable error){
                    SALog(@"response: %@ error: %@", response, error);
                };
                SEL sharedManagerSelector = NSSelectorFromString(@"evaluateJavaScript:completionHandler:");
                if (sharedManagerSelector) {
                    ((void (*)(id, SEL, NSString *, Myblock))[webView methodForSelector:sharedManagerSelector])(webView, sharedManagerSelector, js, myBlock);
                }
                return YES;
            } else if ([urlstr rangeOfString:trackEventScheme].location != NSNotFound) {
                if ([paramsDic count] > 0) {
                    NSString *eventInfo = [paramsDic objectForKey:@"event"];
                    if (eventInfo != nil) {
                        NSString* encodedString = [eventInfo stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        [self trackFromH5WithEvent:encodedString enableVerify:enableVerify];
                    }
                }
                return YES;
            }
            return NO;
        } else{
            SADebug(@"showUpWebView: not UIWebView or WKWebView");
            return NO;
        }
    } @catch (NSException *exception) {
        SAError(@"%@: %@", self, exception);
    }
    return NO;
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request andProperties:(NSDictionary *)propertyDict {
    return [self showUpWebView:webView WithRequest:request andProperties:propertyDict enableVerify:NO];
}

- (void)setMaxCacheSize:(UInt64)maxCacheSize {
    if (maxCacheSize > 0) {
        //防止设置的值太小导致事件丢失
        if (maxCacheSize < 10000) {
            maxCacheSize = 10000;
        }
        _maxCacheSize = maxCacheSize;
    }
}

- (UInt64)getMaxCacheSize {
    return _maxCacheSize;
}

- (NSMutableDictionary *)webViewJavascriptBridgeCallbackInfo {
    NSMutableDictionary *libProperties = [[NSMutableDictionary alloc] init];
    [libProperties setValue:@"iOS" forKey:@"type"];
    if ([self loginId] != nil) {
        [libProperties setValue:[self loginId] forKey:@"distinct_id"];
        [libProperties setValue:[NSNumber numberWithBool:YES] forKey:@"is_login"];
    } else{
        [libProperties setValue:[self distinctId] forKey:@"distinct_id"];
        [libProperties setValue:[NSNumber numberWithBool:NO] forKey:@"is_login"];
    }
    return [libProperties copy];
}

- (void)login:(NSString *)loginId {
    if (loginId == nil || loginId.length == 0) {
        SAError(@"%@ cannot login blank login_id: %@", self, loginId);
        return;
    }
    if (loginId.length > 255) {
        SAError(@"%@ max length of login_id is 255, login_id: %@", self, loginId);
        return;
    }
    if (![loginId isEqualToString:[self loginId]]) {
        self.loginId = loginId;
        [self archiveLoginId];
        if (![loginId isEqualToString:[self distinctId]]) {
            self.originalId = [self distinctId];
            [self track:@"$SignUp" withProperties:nil withType:@"track_signup"];
        }
    }
}

- (void)logout {
    self.loginId = NULL;
    [self archiveLoginId];
}

- (NSString *)anonymousId {
    return _distinctId;
}

- (void)resetAnonymousId {
    BOOL isReal;
    self.distinctId = [[self class] getUniqueHardwareId:&isReal];
    [self archiveDistinctId];
}

- (void)trackAppCrash {
    // Install uncaught exception handlers first
    [[SensorsAnalyticsExceptionHandler sharedHandler] addSensorsAnalyticsInstance:self];
}

- (void)enableAutoTrack {
    [self enableAutoTrack:SensorsAnalyticsEventTypeAppStart | SensorsAnalyticsEventTypeAppEnd];
}

- (void)enableAutoTrack:(SensorsAnalyticsAutoTrackEventType)eventType {
    if (_autoTrackEventType != eventType) {
        _autoTrackEventType = eventType;
        _autoTrack = (_autoTrackEventType != SensorsAnalyticsEventTypeNone);
    }
    // 是否首次启动
    BOOL isFirstStart = NO;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {
        isFirstStart = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([self isLaunchedPassively]) {
            // 追踪 AppStart 事件
            if ([self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppStart] == NO) {
                [self track:@"$AppStartPassively" withProperties:@{
                                                             RESUME_FROM_BACKGROUND_PROPERTY : @(_appRelaunched),
                                                             APP_FIRST_START_PROPERTY : @(isFirstStart),
                                                             }];
            }
        } else {
            // 追踪 AppStart 事件
            if ([self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppStart] == NO) {
                [self track:APP_START_EVENT withProperties:@{
                                                             RESUME_FROM_BACKGROUND_PROPERTY : @(_appRelaunched),
                                                             APP_FIRST_START_PROPERTY : @(isFirstStart),
                                                             }];
            }
            // 启动 AppEnd 事件计时器
            if ([self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppEnd] == NO) {
                [self trackTimer:APP_END_EVENT withTimeUnit:SensorsAnalyticsTimeUnitSeconds];
            }
        }
    });
}

- (BOOL)isAutoTrackEnabled {
    if (sharedInstance.remoteConfig.disableSDK == YES) {
        return NO;
    }
    if (self.remoteConfig.autoTrackMode != kSAAutoTrackModeDefault) {
        if (self.remoteConfig.autoTrackMode == kSAAutoTrackModeDisabledAll) {
            return NO;
        } else {
            return YES;
        }
    }
    return _autoTrack;
}

- (BOOL)isAutoTrackEventTypeIgnored:(SensorsAnalyticsAutoTrackEventType)eventType {

    if (sharedInstance.remoteConfig.disableSDK == YES) {
        return YES;
    }
    if (self.remoteConfig.autoTrackMode != kSAAutoTrackModeDefault) {
        if (self.remoteConfig.autoTrackMode == kSAAutoTrackModeDisabledAll) {
            return YES;
        } else {
            return !(self.remoteConfig.autoTrackMode & eventType);
        }
    }
    return !(_autoTrackEventType & eventType);
}






- (void)ignoreAutoTrackEventType:(SensorsAnalyticsAutoTrackEventType)eventType {
    _autoTrackEventType = _autoTrackEventType ^ eventType;
}

- (void)showDebugInfoView:(BOOL)show {
    _showDebugAlertView = show;
}

- (void)flushByType:(NSString *)type withSize:(int)flushSize andFlushMethod:(BOOL (^)(NSArray *, NSString *))flushMethod {
    while (true) {
        NSArray *recordArray = [self.messageQueue getFirstRecords:flushSize withType:type];
        if (recordArray == nil) {
            SAError(@"Failed to get records from SQLite.");
            break;
        }
        
        if ([recordArray count] == 0 || !flushMethod(recordArray, type)) {
            break;
        }
        
        if (![self.messageQueue removeFirstRecords:flushSize withType:type]) {
            SAError(@"Failed to remove records from SQLite.");
            break;
        }
    }
}

- (void)_flush:(BOOL) vacuumAfterFlushing {
    if (_serverURL == nil || [_serverURL isEqualToString:@""]) {
        return;
    }
    // 判断当前网络类型是否符合同步数据的网络策略
    NSString *networkType = [SensorsAnalyticsSDK getNetWorkStates];
    if (!([self toNetworkType:networkType] & _networkTypePolicy)) {
        return;
    }
    // 使用 Post 发送数据
    BOOL (^flushByPost)(NSArray *, NSString *) = ^(NSArray *recordArray, NSString *type) {
        NSString *jsonString;
        NSData *zippedData;
        NSString *b64String;
        NSString *postBody;
        @try {
            // 1. 先完成这一系列Json字符串的拼接
            jsonString = [NSString stringWithFormat:@"[%@]",[recordArray componentsJoinedByString:@","]];
            // 2. 使用gzip进行压缩
            zippedData = [SAGzipUtility gzipData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
            // 3. base64
            b64String = [zippedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
            int hashCode = [b64String sensorsdata_hashCode];
            b64String = (id)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                  (CFStringRef)b64String,
                                                                                  NULL,
                                                                                  CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                  kCFStringEncodingUTF8));
        
            postBody = [NSString stringWithFormat:@"gzip=1&data_list=%@&crc=%d", b64String, hashCode];
        } @catch (NSException *exception) {
            SAError(@"%@ flushByPost format data error: %@", self, exception);
            return YES;
        }
        
        NSURL *URL = [NSURL URLWithString:self.serverURL];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
        // 普通事件请求，使用标准 UserAgent
        [request setValue:@"SensorsAnalytics iOS SDK" forHTTPHeaderField:@"User-Agent"];
        if (_debugMode == SensorsAnalyticsDebugOnly) {
            [request setValue:@"true" forHTTPHeaderField:@"Dry-Run"];
        }
        
        //Cookie
        [request setValue:[[SensorsAnalyticsSDK sharedInstance] getCookieWithDecode:NO] forHTTPHeaderField:@"Cookie"];

        dispatch_semaphore_t flushSem = dispatch_semaphore_create(0);
        __block BOOL flushSucc = YES;
        
        void (^block)(NSData*, NSURLResponse*, NSError*) = ^(NSData *data, NSURLResponse *response, NSError *error) {
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
                if (_debugMode != SensorsAnalyticsDebugOff) {
                    if (statusCode >= 300) {
                        [self showDebugModeWarning:errMsg withNoMoreButton:YES];
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
                @try {
                    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                    NSString *logString=[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
                    SAError(@"%@ %@: %@", self,messageDesc,logString);
                } @catch (NSException *exception) {
                    SAError(@"%@: %@", self, exception);
                }
            }
            if (statusCode != 200) {
                SAError(@"%@ ret_code: %ld", self, statusCode);
                SAError(@"%@ ret_content: %@", self, urlResponseContent);
            }
            dispatch_semaphore_signal(flushSem);
        };
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:block];
        
        [task resume];
#else
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
         ^(NSURLResponse *response, NSData* data, NSError *error) {
             return block(data, response, error);
        }];
#endif
        
        dispatch_semaphore_wait(flushSem, DISPATCH_TIME_FOREVER);
        
        return flushSucc;
    };
    
    [self flushByType:@"Post" withSize:(_debugMode == SensorsAnalyticsDebugOff ? 50 : 1) andFlushMethod:flushByPost];
    
    if (vacuumAfterFlushing) {
        if (![self.messageQueue vacuum]) {
            SAError(@"failed to VACUUM SQLite.");
        }
    }
    
    SADebug(@"events flushed.");
}

- (void)flush {
    dispatch_async(self.serialQueue, ^{
        [self _flush:NO];
    });
}

- (void)deleteAll {
    [self.messageQueue deleteAll];
}


- (BOOL) isValidName : (NSString *) name {
    @try {
        if (_deviceModel == nil) {
            _deviceModel = [self deviceModel];
        }

        if (_osVersion == nil) {
            UIDevice *device = [UIDevice currentDevice];
            _osVersion = [device systemVersion];
        }

        //据反馈，该函数在 iPhone 8、iPhone 8 Plus，并且系统版本号为 11.0 上可能会 crash，具体原因暂未查明
        if ([_osVersion isEqualToString:@"11.0"]) {
            if ([_deviceModel isEqualToString:@"iPhone10,1"] ||
                [_deviceModel isEqualToString:@"iPhone10,4"] ||
                [_deviceModel isEqualToString:@"iPhone10,2"] ||
                [_deviceModel isEqualToString:@"iPhone10,5"]) {
                    return YES;
            }
        }
        return [self.regexTestName evaluateWithObject:name];
    } @catch (NSException *exception) {
        SAError(@"%@: %@", self, exception);
        return NO;
    }
}

- (NSString *)filePathForData:(NSString *)data {
    NSString *filename = [NSString stringWithFormat:@"sensorsanalytics-%@.plist", data];
    NSString *filepath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
            stringByAppendingPathComponent:filename];
    SADebug(@"filepath for %@ is %@", data, filepath);
    return filepath;
}

- (void)enqueueWithType:(NSString *)type andEvent:(NSDictionary *)e {
    NSMutableDictionary *event = [[NSMutableDictionary alloc] initWithDictionary:e];
    [self.messageQueue addObejct:event withType:@"Post"];
}

- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict withType:(NSString *)type {
    if (self.remoteConfig.disableSDK) {
        return;
    }
    // 对于type是track数据，它们的event名称是有意义的
    if ([type isEqualToString:@"track"]) {
        if (event == nil || [event length] == 0) {
            NSString *errMsg = @"SensorsAnalytics track called with empty event parameter";
            SAError(@"%@", errMsg);
            if (_debugMode != SensorsAnalyticsDebugOff) {
                [self showDebugModeWarning:errMsg withNoMoreButton:YES];
            }
            return;
        }
        if (![self isValidName:event]) {
            NSString *errMsg = [NSString stringWithFormat:@"Event name[%@] not valid", event];
            SAError(@"%@", errMsg);
            if (_debugMode != SensorsAnalyticsDebugOff) {
                [self showDebugModeWarning:errMsg withNoMoreButton:YES];
            }
            return;
        }
    }
    
    if (propertieDict) {
        if (![self assertPropertyTypes:[propertieDict copy] withEventType:type]) {
            SAError(@"%@ failed to track event.", self);
            return;
        }
    }
    
    NSMutableDictionary *libProperties = [[NSMutableDictionary alloc] init];
    
    [libProperties setValue:[_automaticProperties objectForKey:@"$lib"] forKey:@"$lib"];
    [libProperties setValue:[_automaticProperties objectForKey:@"$lib_version"] forKey:@"$lib_version"];
    
    id app_version = [_automaticProperties objectForKey:@"$app_version"];
    if (app_version) {
        [libProperties setValue:app_version forKey:@"$app_version"];
    }
    
    [libProperties setValue:@"code" forKey:@"$lib_method"];

    NSString *lib_detail = nil;
#ifndef SENSORS_ANALYTICS_DISABLE_CALL_STACK
    NSArray *syms = [NSThread callStackSymbols];
    
    if ([syms count] > 2 && !lib_detail) {
        NSString *trace = [syms objectAtIndex:2];
        
        NSRange start = [trace rangeOfString:@"["];
        NSRange end = [trace rangeOfString:@"]"];
        if (start.location != NSNotFound && end.location != NSNotFound && end.location > start.location) {
            NSString *trace_info = [trace substringWithRange:NSMakeRange(start.location+1, end.location-(start.location+1))];
            NSRange split = [trace_info rangeOfString:@" "];
            NSString *class = [trace_info substringWithRange:NSMakeRange(0, split.location)];
            NSString *function = [trace_info substringWithRange:NSMakeRange(split.location + 1, trace_info.length-(split.location + 1))];
            
            lib_detail = [NSString stringWithFormat:@"%@##%@####", class, function];
        }
    }
#endif

    if (lib_detail) {
        [libProperties setValue:lib_detail forKey:@"$lib_detail"];
    }

    //获取用户自定义的动态公共属性
    NSDictionary *dynamicSuperPropertiesDict = self.dynamicSuperProperties?self.dynamicSuperProperties():nil;
    if (dynamicSuperPropertiesDict && [dynamicSuperPropertiesDict isKindOfClass:NSDictionary.class] == NO) {
        SALog(@"dynamicSuperProperties  returned: %@  is not an NSDictionary Obj.",dynamicSuperPropertiesDict);
        dynamicSuperPropertiesDict = nil;
    } else {
        if ([self assertPropertyTypes:dynamicSuperPropertiesDict withEventType:@"register_super_properties"] == NO) {
            dynamicSuperPropertiesDict = nil;
        }
    }

    dispatch_async(self.serialQueue, ^{
        NSNumber *currentSystemUpTime = @([[self class] getSystemUpTime]);
        NSNumber *timeStamp = @([[self class] getCurrentTime]);
        NSMutableDictionary *p = [NSMutableDictionary dictionary];
        if ([type isEqualToString:@"track"] || [type isEqualToString:@"track_signup"]) {
            // track / track_signup 类型的请求，还是要加上各种公共property
            // 这里注意下顺序，按照优先级从低到高，依次是automaticProperties, superProperties,dynamicSuperPropertiesDict,propertieDict
            [p addEntriesFromDictionary:_automaticProperties];
            [p addEntriesFromDictionary:_superProperties];
            [p addEntriesFromDictionary:dynamicSuperPropertiesDict];

            //update lib $app_version from super properties
            id app_version = [_superProperties objectForKey:@"$app_version"];
            if (app_version) {
                [libProperties setValue:app_version forKey:@"$app_version"];
            }

            // 每次 track 时手机网络状态
            NSString *networkType = [SensorsAnalyticsSDK getNetWorkStates];
            [p setObject:networkType forKey:@"$network_type"];
            if ([networkType isEqualToString:@"WIFI"]) {
                [p setObject:@YES forKey:@"$wifi"];
            } else {
                [p setObject:@NO forKey:@"$wifi"];
            }

            NSDictionary *eventTimer = self.trackTimer[event];
            if (eventTimer) {
                [self.trackTimer removeObjectForKey:event];
                NSNumber *eventBegin = [eventTimer valueForKey:@"eventBegin"];
                NSNumber *eventAccumulatedDuration = [eventTimer objectForKey:@"eventAccumulatedDuration"];
                SensorsAnalyticsTimeUnit timeUnit = [[eventTimer valueForKey:@"timeUnit"] intValue];
                
                float eventDuration;
                if (eventAccumulatedDuration) {
                    eventDuration = [currentSystemUpTime longValue] - [eventBegin longValue] + [eventAccumulatedDuration longValue];
                } else {
                    eventDuration = [currentSystemUpTime longValue] - [eventBegin longValue];
                }

                if (eventDuration < 0) {
                    eventDuration = 0;
                }

                if (eventDuration > 0 && eventDuration < 24 * 60 * 60 * 1000) {
                    switch (timeUnit) {
                        case SensorsAnalyticsTimeUnitHours:
                            eventDuration = eventDuration / 60.0;
                        case SensorsAnalyticsTimeUnitMinutes:
                            eventDuration = eventDuration / 60.0;
                        case SensorsAnalyticsTimeUnitSeconds:
                            eventDuration = eventDuration / 1000.0;
                        case SensorsAnalyticsTimeUnitMilliseconds:
                            break;
                    }
                    @try {
                        [p setObject:@([[NSString stringWithFormat:@"%.3f", eventDuration] floatValue]) forKey:@"event_duration"];
                    } @catch (NSException *exception) {
                        SAError(@"%@: %@", self, exception);
                    }
                }
            }
        }
        
        NSString *project = nil;
        NSString *token = nil;
        if (propertieDict) {
            NSArray *keys = propertieDict.allKeys;
            for (id key in keys) {
                NSObject *obj = propertieDict[key];
                if ([@"$project" isEqualToString:key]) {
                    project = (NSString *)obj;
                } else if ([@"$token" isEqualToString:key]) {
                    token = (NSString *)obj;
                } else {
                    if ([obj isKindOfClass:[NSDate class]]) {
                        // 序列化所有 NSDate 类型
                        NSString *dateStr = [_dateFormatter stringFromDate:(NSDate *)obj];
                        [p setObject:dateStr forKey:key];
                    } else {
                        [p setObject:obj forKey:key];
                    }
                }
            }
        }
        
        //不允许通过公共属性或者自定义属性覆盖 $device_id
        //[p setObject:[_automaticProperties objectForKey:@"$device_id"] forKey:@"$device_id"];

        NSMutableDictionary *e;
        NSString *bestId;
        if ([self loginId] != nil) {
            bestId = [self loginId];
        } else{
            bestId = [self distinctId];
        }

        if (bestId == nil) {
            [self resetAnonymousId];
            bestId = [self anonymousId];
        }

        if ([type isEqualToString:@"track_signup"]) {
            e = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                 event, @"event",
                 [NSDictionary dictionaryWithDictionary:p], @"properties",
                 bestId, @"distinct_id",
                 self.originalId, @"original_id",
                 timeStamp, @"time",
                 type, @"type",
                 libProperties, @"lib",
                 @(arc4random()), @"_track_id",
                 nil];
        } else if([type isEqualToString:@"track"]){
            //  是否首日访问
            if ([self isFirstDay]) {
                [p setObject:@YES forKey:@"$is_first_day"];
            } else {
                [p setObject:@NO forKey:@"$is_first_day"];
            }

            @try {
                if ([self isLaunchedPassively]) {
                    [p setObject:@"background" forKey:@"$app_state"];
                }
            } @catch (NSException *e) {
                SAError(@"%@: %@", self, e);
            }

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
            @try {
                //采集设备方向
                if (self.deviceOrientationConfig.enableTrackScreenOrientation && self.deviceOrientationConfig.deviceOrientation.length) {
                    [p setObject:self.deviceOrientationConfig.deviceOrientation forKey:@"$screen_orientation"];
                }
            } @catch (NSException *e) {
                 SAError(@"%@: %@", self, e);
            }
#endif

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
            @try {
                //采集地理位置信息
                if (self.locationConfig.enableGPSLocation) {
                    if (CLLocationCoordinate2DIsValid(self.locationConfig.coordinate)) {
                        NSInteger latitude = self.locationConfig.coordinate.latitude * pow(10, 6);
                        NSInteger longitude = self.locationConfig.coordinate.longitude * pow(10, 6);
                        [p setObject:@(latitude) forKey:@"$latitude"];
                        [p setObject:@(longitude) forKey:@"$longitude"];
                    }
                }
            } @catch (NSException *e) {
                SAError(@"%@: %@", self, e);
            }
#endif
            e = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                 event, @"event",
                 [NSDictionary dictionaryWithDictionary:p], @"properties",
                 bestId, @"distinct_id",
                 timeStamp, @"time",
                 type, @"type",
                 libProperties, @"lib",
                 @(arc4random()), @"_track_id",
                 nil];
        } else {
            // 此时应该都是对Profile的操作
            e = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                 [NSDictionary dictionaryWithDictionary:p], @"properties",
                 bestId, @"distinct_id",
                 timeStamp, @"time",
                 type, @"type",
                 libProperties, @"lib",
                 @(arc4random()), @"_track_id",
                 nil];
        }

        if (project) {
            [e setObject:project forKey:@"project"];
        }
        if (token) {
            [e setObject:token forKey:@"token"];
        }

        SALog(@"\n【track event】:\n%@", e);
        
        [self enqueueWithType:type andEvent:[e copy]];
        
        if (_debugMode != SensorsAnalyticsDebugOff) {
            // 在DEBUG模式下，直接发送事件
            [self flush];
        } else {
            // 否则，在满足发送条件时，发送事件
            if ([type isEqualToString:@"track_signup"] || [[self messageQueue] count] >= self.flushBulkSize) {
                [self flush];
            }
        }
    });
}

- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict {
    [self track:event withProperties:propertieDict withType:@"track"];
}

- (void)track:(NSString *)event {
    [self track:event withProperties:nil withType:@"track"];
}

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

- (NSString *)getCookieWithDecode:(BOOL)decode {
    if (decode) {
        return (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,(__bridge CFStringRef)_cookie, CFSTR(""),CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    } else {
        return _cookie;
    }
}

- (void)trackTimer:(NSString *)event {
    [self trackTimer:event withTimeUnit:SensorsAnalyticsTimeUnitMilliseconds];
}

- (void)trackTimerStart:(NSString *)event {
    [self trackTimer:event withTimeUnit:SensorsAnalyticsTimeUnitSeconds];
}

- (void)trackTimerBegin:(NSString *)event {
    [self trackTimer:event];
}

- (void)trackTimerBegin:(NSString *)event withTimeUnit:(SensorsAnalyticsTimeUnit)timeUnit {
    [self trackTimer:event withTimeUnit:timeUnit];
}

- (void)trackTimer:(NSString *)event withTimeUnit:(SensorsAnalyticsTimeUnit)timeUnit {
    if (![self isValidName:event]) {
        NSString *errMsg = [NSString stringWithFormat:@"Event name[%@] not valid", event];
        SAError(@"%@", errMsg);
        if (_debugMode != SensorsAnalyticsDebugOff) {
            [self showDebugModeWarning:errMsg withNoMoreButton:YES];
        }
        return;
    }
    
    NSNumber *eventBegin = @([[self class] getSystemUpTime]);
    dispatch_async(self.serialQueue, ^{
        self.trackTimer[event] = @{@"eventBegin" : eventBegin, @"eventAccumulatedDuration" : [NSNumber numberWithLong:0], @"timeUnit" : [NSNumber numberWithInt:timeUnit]};
    });
}

- (void)trackTimerEnd:(NSString *)event {
    [self track:event];
}

- (void)trackTimerEnd:(NSString *)event withProperties:(NSDictionary *)propertyDict {
    [self track:event withProperties:propertyDict];
}

- (void)clearTrackTimer {
    dispatch_async(self.serialQueue, ^{
        self.trackTimer = [NSMutableDictionary dictionary];
    });
}

- (void)trackSignUp:(NSString *)newDistinctId withProperties:(NSDictionary *)propertieDict {
    [self identify:newDistinctId];
    [self track:@"$SignUp" withProperties:propertieDict withType:@"track_signup"];
}

- (void)trackSignUp:(NSString *)newDistinctId {
    [self identify:newDistinctId];
    [self track:@"$SignUp" withProperties:nil withType:@"track_signup"];
}

- (void)trackInstallation:(NSString *)event withProperties:(NSDictionary *)propertyDict disableCallback:(BOOL)disableCallback {
    BOOL hasTrackInstallation = NO;
    NSString *userDefaultsKey = nil;
    if (disableCallback) {
        userDefaultsKey = @"HasTrackInstallationWithDisableCallback";
        hasTrackInstallation = [SAKeyChainItemWrapper hasTrackInstallationWithDisableCallback];
    } else {
        userDefaultsKey = @"HasTrackInstallation";
        hasTrackInstallation = [SAKeyChainItemWrapper hasTrackInstallation];
    }

    if (hasTrackInstallation) {
        return;
    }

    if (![[NSUserDefaults standardUserDefaults] boolForKey:userDefaultsKey]) {
        hasTrackInstallation = NO;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:userDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        hasTrackInstallation = YES;
    }
    if (disableCallback) {
        [SAKeyChainItemWrapper markHasTrackInstallationWithDisableCallback];
    }else{
        [SAKeyChainItemWrapper markHasTrackInstallation];
    }
    if (!hasTrackInstallation) {
        // 追踪渠道是特殊功能，需要同时发送 track 和 profile_set_once
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        NSString *idfa = [self getIDFA];
        if (idfa != nil) {
            [properties setValue:[NSString stringWithFormat:@"idfa=%@", idfa] forKey:@"$ios_install_source"];
        } else {
            [properties setValue:@"" forKey:@"$ios_install_source"];
        }

        if (disableCallback) {
            [properties setValue:@YES forKey:@"$ios_install_disable_callback"];
        }

        if (_userAgent) {
            [properties setValue:_userAgent forKey:@"$user_agent"];
        }

        if (propertyDict != nil) {
            [properties addEntriesFromDictionary:propertyDict];
        }

        // 先发送 track
        [self track:event withProperties:properties withType:@"track"];

        // 再发送 profile_set_once
        NSMutableDictionary *profileProperties = [properties mutableCopy];
        [profileProperties setValue:[NSDate date] forKey:@"$first_visit_time"];
        [self track:nil withProperties:profileProperties withType:@"profile_set_once"];

        [self flush];
    }
}

- (void)trackInstallation:(NSString *)event withProperties:(NSDictionary *)propertyDict {
    [self trackInstallation:event withProperties:propertyDict disableCallback:NO];
}

- (void)trackInstallation:(NSString *)event {
    [self trackInstallation:event withProperties:nil disableCallback:NO];
}

- (NSString  *)getIDFA {
    NSString *idfa = nil;
    @try {
//#if defined(SENSORS_ANALYTICS_IDFA)
        Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
        if (ASIdentifierManagerClass) {
            SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
            id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
            SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
            NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
            NSString *temp = [uuid UUIDString];
            // 在 iOS 10.0 以后，当用户开启限制广告跟踪，advertisingIdentifier 的值将是全零
            // 00000000-0000-0000-0000-000000000000
            if (temp && ![temp hasPrefix:@"00000000"]) {
                idfa = temp;
            }
        }
//#endif
        return idfa;
    } @catch (NSException *exception) {
        SADebug(@"%@: %@", self, exception);
        return idfa;
    }
}


- (void)identify:(NSString *)distinctId {
    if (distinctId == nil || distinctId.length == 0) {
        SAError(@"%@ cannot identify blank distinct id: %@", self, distinctId);
//        @throw [NSException exceptionWithName:@"InvalidDataException" reason:@"SensorsAnalytics distinct_id should not be nil or empty" userInfo:nil];
    }
    if (distinctId.length > 255) {
        SAError(@"%@ max length of distinct_id is 255, distinct_id: %@", self, distinctId);
//        @throw [NSException exceptionWithName:@"InvalidDataException" reason:@"SensorsAnalytics max length of distinct_id is 255" userInfo:nil];
    }
    dispatch_async(self.serialQueue, ^{
        // 先把之前的distinctId设为originalId
        self.originalId = self.distinctId;
        // 更新distinctId
        self.distinctId = distinctId;
        [self archiveDistinctId];
    });
}

- (NSString *)deviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char answer[size];
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *results = @(answer);
    return results;
}

- (NSString *)libVersion {
    return VERSION;
}

- (BOOL)assertPropertyTypes:(NSDictionary *)properties withEventType:(NSString *)eventType {
    for (id __unused k in properties) {
        // key 必须是NSString
        if (![k isKindOfClass: [NSString class]]) {
            NSString *errMsg = @"Property Key should by NSString";
            SAError(@"%@", errMsg);
            if (_debugMode != SensorsAnalyticsDebugOff) {
                [self showDebugModeWarning:errMsg withNoMoreButton:YES];
            }
            return NO;
        }
        
        // key的名称必须符合要求
        if (![self isValidName: k]) {
            NSString *errMsg = [NSString stringWithFormat:@"property name[%@] is not valid", k];
            SAError(@"%@", errMsg);
            if (_debugMode != SensorsAnalyticsDebugOff) {
                [self showDebugModeWarning:errMsg withNoMoreButton:YES];
            }
            return NO;
        }
        
        // value的类型检查
        if( ![properties[k] isKindOfClass:[NSString class]] &&
           ![properties[k] isKindOfClass:[NSNumber class]] &&
           ![properties[k] isKindOfClass:[NSNull class]] &&
           ![properties[k] isKindOfClass:[NSSet class]] &&
           ![properties[k] isKindOfClass:[NSDate class]]) {
            NSString * errMsg = [NSString stringWithFormat:@"%@ property values must be NSString, NSNumber, NSSet or NSDate. got: %@ %@", self, [properties[k] class], properties[k]];
            SAError(@"%@", errMsg);
            if (_debugMode != SensorsAnalyticsDebugOff) {
                [self showDebugModeWarning:errMsg withNoMoreButton:YES];
            }
            return NO;
        }
        
        // NSSet 类型的属性中，每个元素必须是 NSString 类型
        if ([properties[k] isKindOfClass:[NSSet class]]) {
            NSEnumerator *enumerator = [((NSSet *)properties[k]) objectEnumerator];
            id object;
            while (object = [enumerator nextObject]) {
                if (![object isKindOfClass:[NSString class]]) {
                    NSString * errMsg = [NSString stringWithFormat:@"%@ value of NSSet must be NSString. got: %@ %@", self, [object class], object];
                    SAError(@"%@", errMsg);
                    if (_debugMode != SensorsAnalyticsDebugOff) {
                        [self showDebugModeWarning:errMsg withNoMoreButton:YES];
                    }
                    return NO;
                }
                NSUInteger objLength = [((NSString *)object) lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
                if (objLength > PROPERTY_LENGTH_LIMITATION) {
                    NSString * errMsg = [NSString stringWithFormat:@"%@ The value in NSString is too long: %@", self, (NSString *)object];
                    SAError(@"%@", errMsg);
                    if (_debugMode != SensorsAnalyticsDebugOff) {
                        [self showDebugModeWarning:errMsg withNoMoreButton:YES];
                    }
                    return NO;
                }
            }
        }
        
        // NSString 检查长度，但忽略部分属性
        if ([properties[k] isKindOfClass:[NSString class]]) {
            NSUInteger objLength = [((NSString *)properties[k]) lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            NSUInteger valueMaxLength = PROPERTY_LENGTH_LIMITATION;
            if ([k isEqualToString:@"app_crashed_reason"]) {
                valueMaxLength = PROPERTY_LENGTH_LIMITATION * 2;
            }
            if (objLength > valueMaxLength) {
                NSString * errMsg = [NSString stringWithFormat:@"%@ The value in NSString is too long: %@", self, (NSString *)properties[k]];
                SAError(@"%@", errMsg);
                if (_debugMode != SensorsAnalyticsDebugOff) {
                    [self showDebugModeWarning:errMsg withNoMoreButton:YES];
                }
                return NO;
            }
        }
        
        // profileIncrement的属性必须是NSNumber
        if ([eventType isEqualToString:@"profile_increment"]) {
            if (![properties[k] isKindOfClass:[NSNumber class]]) {
                NSString *errMsg = [NSString stringWithFormat:@"%@ profile_increment value must be NSNumber. got: %@ %@", self, [properties[k] class], properties[k]];
                SAError(@"%@", errMsg);
                if (_debugMode != SensorsAnalyticsDebugOff) {
                    [self showDebugModeWarning:errMsg withNoMoreButton:YES];
                }
                return NO;
            }
        }
        
        // profileAppend的属性必须是个NSSet
        if ([eventType isEqualToString:@"profile_append"]) {
            if (![properties[k] isKindOfClass:[NSSet class]]) {
                NSString *errMsg = [NSString stringWithFormat:@"%@ profile_append value must be NSSet. got %@ %@", self, [properties[k] class], properties[k]];
                SAError(@"%@", errMsg);
                if (_debugMode != SensorsAnalyticsDebugOff) {
                    [self showDebugModeWarning:errMsg withNoMoreButton:YES];
                }
                return NO;
            }
        }
    }
    return YES;
}

- (NSDictionary *)collectAutomaticProperties {
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    UIDevice *device = [UIDevice currentDevice];
    _deviceModel = [self deviceModel];
    _osVersion = [device systemVersion];
    struct CGSize size = [UIScreen mainScreen].bounds.size;
    CTCarrier *carrier = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];
    // Use setValue semantics to avoid adding keys where value can be nil.
    [p setValue:[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] forKey:@"$app_version"];
    if (carrier != nil) {
        NSString *networkCode = [carrier mobileNetworkCode];
        NSString *countryCode = [carrier mobileCountryCode];
        
        NSString *carrierName = nil;
        //中国运营商
        if (countryCode && [countryCode isEqualToString:CARRIER_CHINA_MCC]) {
            if (networkCode) {
                
                //中国移动
                if ([networkCode isEqualToString:@"00"] || [networkCode isEqualToString:@"02"] || [networkCode isEqualToString:@"07"] || [networkCode isEqualToString:@"08"]) {
                    carrierName= @"中国移动";
                }
                //中国联通
                if ([networkCode isEqualToString:@"01"] || [networkCode isEqualToString:@"06"] || [networkCode isEqualToString:@"09"]) {
                    carrierName= @"中国联通";
                }
                //中国电信
                if ([networkCode isEqualToString:@"03"] || [networkCode isEqualToString:@"05"] || [networkCode isEqualToString:@"11"]) {
                    carrierName= @"中国电信";
                }
                //中国卫通
                if ([networkCode isEqualToString:@"04"]) {
                    carrierName= @"中国卫通";
                }
                //中国铁通
                if ([networkCode isEqualToString:@"20"]) {
                    carrierName= @"中国铁通";
                }
            }
        } else { //国外运营商解析
            //加载当前 bundle
            NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[SensorsAnalyticsSDK class]] pathForResource:@"SensorsAnalyticsSDK" ofType:@"bundle"]];
            //文件路径
            NSString *jsonPath = [sensorsBundle pathForResource:@"sa_mcc_mnc_mini.json" ofType:nil];
            NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
            if (jsonData) {
                NSDictionary *dicAllMcc =  [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
                if (dicAllMcc) {
                    NSString *mccMncKey = [NSString stringWithFormat:@"%@%@",countryCode,networkCode];
                    carrierName = dicAllMcc[mccMncKey];
                }
            }
        }
        
        if (carrierName != nil) {
            [p setValue:carrierName forKey:@"$carrier"];
        } else {
            if (carrier.carrierName) {
                [p setValue:carrier.carrierName forKey:@"$carrier"];
            }
        }
    }
    
    BOOL isReal;
    [p setValue:[[self class] getUniqueHardwareId:&isReal] forKey:@"$device_id"];
    [p addEntriesFromDictionary:@{
                                  @"$lib": @"iOS",
                                  @"$lib_version": [self libVersion],
                                  @"$manufacturer": @"Apple",
                                  @"$os": @"iOS",
                                  @"$os_version": _osVersion,
                                  @"$model": _deviceModel,
                                  @"$screen_height": @((NSInteger)size.height),
                                  @"$screen_width": @((NSInteger)size.width),
                                      }];
    return [p copy];
}

-(void)registerDynamicSuperProperties:(NSDictionary<NSString *,id> *(^)(void)) dynamicSuperProperties {
     dispatch_async(self.serialQueue, ^{
         self.dynamicSuperProperties = dynamicSuperProperties;
     });
}

- (void)registerSuperProperties:(NSDictionary *)propertyDict {
    propertyDict = [propertyDict copy];
    if (![self assertPropertyTypes:propertyDict withEventType:@"register_super_properties"]) {
        SAError(@"%@ failed to register super properties.", self);
        return;
    }
    dispatch_async(self.serialQueue, ^{
        // 注意这里的顺序，发生冲突时是以propertyDict为准，所以它是后加入的
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:_superProperties];
        [tmp addEntriesFromDictionary:propertyDict];
        _superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        [self archiveSuperProperties];
    });
}

- (void)unregisterSuperProperty:(NSString *)property {
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:_superProperties];
        if (tmp[property] != nil) {
            [tmp removeObjectForKey:property];
        }
        _superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        [self archiveSuperProperties];
    });
    
}

- (void)clearSuperProperties {
    dispatch_async(self.serialQueue, ^{
        _superProperties = @{};
        [self archiveSuperProperties];
    });
}

- (NSDictionary *)currentSuperProperties {
    return [_superProperties copy];
}

#pragma mark - Local caches

- (void)unarchive {
    [self unarchiveDistinctId];
    [self unarchiveLoginId];
    [self unarchiveSuperProperties];
    [self unarchiveFirstDay];
}

- (id)unarchiveFromFile:(NSString *)filePath {
    id unarchivedData = nil;
    @try {
        unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    } @catch (NSException *exception) {
        SAError(@"%@ unable to unarchive data in %@, starting fresh", self, filePath);
        unarchivedData = nil;
    }
    return unarchivedData;
}

- (void)unarchiveDistinctId {
    NSString *archivedDistinctId = (NSString *)[self unarchiveFromFile:[self filePathForData:@"distinct_id"]];
    NSString *distinctIdInKeychain = [SAKeyChainItemWrapper saUdid];
    if (distinctIdInKeychain != nil && distinctIdInKeychain.length>0) {
        self.distinctId = distinctIdInKeychain;
    } else {
        if (archivedDistinctId == nil) {
            BOOL isReal;
            self.distinctId = [[self class] getUniqueHardwareId:&isReal];
        } else {
            self.distinctId = archivedDistinctId;
        }
    }
    [self archiveDistinctId];
}

- (void)unarchiveLoginId {
    NSString *archivedLoginId = (NSString *)[self unarchiveFromFile:[self filePathForData:@"login_id"]];
    self.loginId = archivedLoginId;
}

- (void)unarchiveFirstDay {
    NSString *archivedFirstDay = (NSString *)[self unarchiveFromFile:[self filePathForData:@"first_day"]];
    self.firstDay = archivedFirstDay;
}

- (void)unarchiveSuperProperties {
    NSDictionary *archivedSuperProperties = (NSDictionary *)[self unarchiveFromFile:[self filePathForData:@"super_properties"]];
    if (archivedSuperProperties == nil) {
        _superProperties = [NSDictionary dictionary];
    } else {
        _superProperties = [archivedSuperProperties copy];
    }
}

- (void)archiveDistinctId {
    NSString *filePath = [self filePathForData:@"distinct_id"];
    /* 为filePath文件设置保护等级 */
    NSDictionary *protection = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                           forKey:NSFileProtectionKey];
    [[NSFileManager defaultManager] setAttributes:protection
                                     ofItemAtPath:filePath
                                            error:nil];
    if (![NSKeyedArchiver archiveRootObject:[[self distinctId] copy] toFile:filePath]) {
        SAError(@"%@ unable to archive distinctId", self);
    }
    [SAKeyChainItemWrapper saveUdid:self.distinctId];
    SADebug(@"%@ archived distinctId", self);
}

- (void)archiveLoginId {
    NSString *filePath = [self filePathForData:@"login_id"];
    /* 为filePath文件设置保护等级 */
    NSDictionary *protection = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                           forKey:NSFileProtectionKey];
    [[NSFileManager defaultManager] setAttributes:protection
                                     ofItemAtPath:filePath
                                            error:nil];
    if (![NSKeyedArchiver archiveRootObject:[[self loginId] copy] toFile:filePath]) {
        SAError(@"%@ unable to archive loginId", self);
    }
    SADebug(@"%@ archived loginId", self);
}

- (void)archiveFirstDay {
    NSString *filePath = [self filePathForData:@"first_day"];
    /* 为filePath文件设置保护等级 */
    NSDictionary *protection = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                           forKey:NSFileProtectionKey];
    [[NSFileManager defaultManager] setAttributes:protection
                                     ofItemAtPath:filePath
                                            error:nil];
    if (![NSKeyedArchiver archiveRootObject:[[self firstDay] copy] toFile:filePath]) {
        SAError(@"%@ unable to archive firstDay", self);
    }
    SADebug(@"%@ archived firstDay", self);
}

- (void)archiveSuperProperties {
    NSString *filePath = [self filePathForData:@"super_properties"];
    /* 为filePath文件设置保护等级 */
    NSDictionary *protection = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                           forKey:NSFileProtectionKey];
    [[NSFileManager defaultManager] setAttributes:protection
                                     ofItemAtPath:filePath
                                            error:nil];
    if (![NSKeyedArchiver archiveRootObject:[self.superProperties copy] toFile:filePath]) {
        SAError(@"%@ unable to archive super properties", self);
    }
    SADebug(@"%@ archive super properties data", self);
}

#pragma mark - Network control

+ (NSString *)getNetWorkStates {
#ifdef SA_UT
    SADebug(@"In unit test, set NetWorkStates to wifi");
    return @"WIFI";
#endif
    NSString* network = @"NULL";
    @try {
        SAReachability *reachability = [SAReachability reachabilityForInternetConnection];
        SANetworkStatus status = [reachability currentReachabilityStatus];

        if (status == SAReachableViaWiFi) {
            network = @"WIFI";
        } else if (status == SAReachableViaWWAN) {
            CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
            if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS]) {
                network = @"2G";
            } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge]) {
                network = @"2G";
            } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyWCDMA]) {
                network = @"3G";
            } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSDPA]) {
                network = @"3G";
            } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSUPA]) {
                network = @"3G";
            } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
                network = @"3G";
            } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {
                network = @"3G";
            } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {
                network = @"3G";
            } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {
                network = @"3G";
            } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyeHRPD]) {
                network = @"3G";
            } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) {
                network = @"4G";
            }
        }
    } @catch(NSException *exception) {
        SADebug(@"%@: %@", self, exception);
    }
    return network;
}

- (UInt64)flushInterval {
    @synchronized(self) {
        return _flushInterval;
    }
}

- (void)setFlushInterval:(UInt64)interval {
    @synchronized(self) {
        if (interval < 5 * 1000) {
            interval = 5 * 1000;
        }
        _flushInterval = interval;
    }
    [self flush];
    [self startFlushTimer];
}

- (void)startFlushTimer {
    SADebug(@"starting flush timer.");
    [self stopFlushTimer];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_flushInterval > 0) {
            double interval = _flushInterval > 100 ? (double)_flushInterval / 1000.0 : 0.1f;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          target:self
                                                        selector:@selector(flush)
                                                        userInfo:nil
                                                         repeats:YES];
            [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
        }
    });
}

- (void)stopFlushTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) {
            [self.timer invalidate];
        }
        self.timer = nil;
    });
}

- (UInt64)flushBulkSize {
    @synchronized(self) {
        return _flushBulkSize;
    }
}

- (void)setFlushBulkSize:(UInt64)bulkSize {
    @synchronized(self) {
        _flushBulkSize = bulkSize;
    }
}

- (void)addWebViewUserAgentSensorsDataFlag {
    [self addWebViewUserAgentSensorsDataFlag:YES];
}

- (void)addWebViewUserAgentSensorsDataFlag:(BOOL)enableVerify  {
    [NSThread sa_safelyRunOnMainThreadSync:^{
        BOOL verify = enableVerify;
        @try {
            if (self->_serverURL == nil || self->_serverURL.length == 0) {
                verify = NO;
            }
            SAServerUrl *ss = [[SAServerUrl alloc]initWithUrl:self->_serverURL];
            UIWebView *tempWebView = [[UIWebView alloc] initWithFrame:CGRectZero];
            NSString *oldAgent = [tempWebView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
            NSString *newAgent = oldAgent;
            if ([oldAgent rangeOfString:@"sa-sdk-ios"].location == NSNotFound) {
                if (verify) {
                    newAgent = [oldAgent stringByAppendingString:[NSString stringWithFormat: @" /sa-sdk-ios/sensors-verify/%@?%@ ",ss.host,ss.project]];
                } else {
                    newAgent = [oldAgent stringByAppendingString:@" /sa-sdk-ios"];
                }
            }
            NSDictionary *dictionnary = [[NSDictionary alloc] initWithObjectsAndKeys:newAgent, @"UserAgent", nil];
            [[NSUserDefaults standardUserDefaults] registerDefaults:dictionnary];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } @catch (NSException *exception) {
            SADebug(@"%@: %@", self, exception);
        }
    }
     ];
}

- (SensorsAnalyticsDebugMode)debugMode {
    return _debugMode;
}




#pragma mark - UIApplication Events

- (void)setUpListeners {
    // 监听 App 启动或结束事件
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillEnterForeground:)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminateNotification:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
}



- (void)trackEventFromExtensionWithGroupIdentifier:(NSString *)groupIdentifier completion:(void (^)(NSString *groupIdentifier, NSArray *events)) completion {
    @try {
        if (groupIdentifier == nil || [groupIdentifier isEqualToString:@""]) {
            return;
        }
        NSArray *eventArray = [[SAAppExtensionDataManager sharedInstance] readAllEventsWithGroupIdentifier:groupIdentifier];
        if (eventArray) {
            for (NSDictionary *dict in eventArray) {
                [[SensorsAnalyticsSDK sharedInstance] track:dict[@"event"] withProperties:dict[@"properties"]];
            }
            [[SAAppExtensionDataManager sharedInstance] deleteEventsWithGroupIdentifier:groupIdentifier];
            if (completion) {
                completion(groupIdentifier, eventArray);
            }
        }
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    SADebug(@"%@ application will enter foreground", self);
    
    _appRelaunched = YES;
    _launchOptions = nil;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    SADebug(@"%@ application did become active", self);
    if (_appRelaunched) {
        //下次启动 app 的时候重新初始化
        NSDictionary *sdkConfig = [[NSUserDefaults standardUserDefaults] objectForKey:@"SASDKConfig"];
        [self setSDKWithRemoteConfigDict:sdkConfig];
    }
    if (self.remoteConfig.disableSDK == YES) {
        //停止 SDK 的 flushtimer
        if (self.timer.isValid) {
            [self.timer invalidate];
        }
        self.timer = nil;

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
        //停止采集设备方向信息
        [self.deviceOrientationManager stopDeviceMotionUpdates];
#endif

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
        [self.locationManager stopUpdatingLocation];
#endif

        [self flush];//停止采集数据之后 flush 本地数据
        dispatch_sync(self.serialQueue, ^{
        });

    }else{
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
        if (self.deviceOrientationConfig.enableTrackScreenOrientation) {
            [self.deviceOrientationManager startDeviceMotionUpdates];
        }
#endif

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
        if (self.locationConfig.enableGPSLocation) {
            [self.locationManager startUpdatingLocation];
        }
#endif
    }
    [self requestFunctionalManagermentConfig];
    if (_applicationWillResignActive) {
        _applicationWillResignActive = NO;
        return;
    }
    _applicationWillResignActive = NO;

    // 是否首次启动
    BOOL isFirstStart = NO;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {
        isFirstStart = YES;
    }

    // 遍历 trackTimer ,修改 eventBegin 为当前 currentSystemUpTime
    dispatch_async(self.serialQueue, ^{

        NSNumber *currentSystemUpTime = @([[self class] getSystemUpTime]);
        NSArray *keys = [self.trackTimer allKeys];
        NSString *key = nil;
        NSMutableDictionary *eventTimer = nil;
        for (key in keys) {
            eventTimer = [[NSMutableDictionary alloc] initWithDictionary:self.trackTimer[key]];
            if (eventTimer) {
                [eventTimer setValue:currentSystemUpTime forKey:@"eventBegin"];
                self.trackTimer[key] = eventTimer;
            }
        }
    });

    if ([self isAutoTrackEnabled] && _appRelaunched) {
        // 追踪 AppStart 事件
        if ([self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppStart] == NO) {
            [self track:APP_START_EVENT withProperties:@{
                                                         RESUME_FROM_BACKGROUND_PROPERTY : @(_appRelaunched),
                                                         APP_FIRST_START_PROPERTY : @(isFirstStart),
                                                         }];
        }
        // 启动 AppEnd 事件计时器
        if ([self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppEnd] == NO) {
            [self trackTimer:APP_END_EVENT withTimeUnit:SensorsAnalyticsTimeUnitSeconds];
        }
    }
    
    [self startFlushTimer];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    SADebug(@"%@ application will resign active", self);
    _applicationWillResignActive = YES;
    [self stopFlushTimer];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    SADebug(@"%@ application did enter background", self);
    _applicationWillResignActive = NO;
    _launchOptions = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestFunctionalManagermentConfigWithCompletion:) object:self.reqConfigBlock];

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
    [self.deviceOrientationManager stopDeviceMotionUpdates];
#endif

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
    [self.locationManager stopUpdatingLocation];
#endif

    // 遍历 trackTimer
    // eventAccumulatedDuration = eventAccumulatedDuration + currentSystemUpTime - eventBegin
    dispatch_async(self.serialQueue, ^{
        NSNumber *currentSystemUpTime = @([[self class] getSystemUpTime]);
        NSArray *keys = [self.trackTimer allKeys];
        NSString *key = nil;
        NSMutableDictionary *eventTimer = nil;
        for (key in keys) {
            if (key != nil) {
                if ([key isEqualToString:@"$AppEnd"]) {
                    continue;
                }
            }
            eventTimer = [[NSMutableDictionary alloc] initWithDictionary:self.trackTimer[key]];
            if (eventTimer) {
                NSNumber *eventBegin = [eventTimer valueForKey:@"eventBegin"];
                NSNumber *eventAccumulatedDuration = [eventTimer objectForKey:@"eventAccumulatedDuration"];
                long eventDuration;
                if (eventAccumulatedDuration) {
                    eventDuration = [currentSystemUpTime longValue] - [eventBegin longValue] + [eventAccumulatedDuration longValue];
                } else {
                    eventDuration = [currentSystemUpTime longValue] - [eventBegin longValue];
                }
                [eventTimer setObject:[NSNumber numberWithLong:eventDuration] forKey:@"eventAccumulatedDuration"];
                [eventTimer setObject:currentSystemUpTime forKey:@"eventBegin"];
                self.trackTimer[key] = eventTimer;
            }
        }
    });

    if ([self isAutoTrackEnabled]) {
        // 追踪 AppEnd 事件
        if ([self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppEnd] == NO) {
            [self track:APP_END_EVENT];
        }
    }
    
    if (self.flushBeforeEnterBackground) {
        dispatch_async(self.serialQueue, ^{
            [self _flush:YES];
        });
    }
}

-(void)applicationWillTerminateNotification:(NSNotification *)notification {
    SALog(@"applicationWillTerminateNotification");
    dispatch_sync(self.serialQueue, ^{
    });
}

#pragma mark - SensorsData  Analytics

- (void)set:(NSDictionary *)profileDict {
    [[self people] set:profileDict];
}

- (void)setOnce:(NSDictionary *)profileDict {
    [[self people] setOnce:profileDict];
}

- (void)set:(NSString *) profile to:(id)content {
    [[self people] set:profile to:content];
}

- (void)setOnce:(NSString *) profile to:(id)content {
    [[self people] setOnce:profile to:content];
}

- (void)unset:(NSString *) profile {
    [[self people] unset:profile];
}

- (void)increment:(NSString *)profile by:(NSNumber *)amount {
    [[self people] increment:profile by:amount];
}

- (void)increment:(NSDictionary *)profileDict {
    [[self people] increment:profileDict];
}

- (void)append:(NSString *)profile by:(NSSet *)content {
    [[self people] append:profile by:content];
}

- (void)deleteUser {
    [[self people] deleteUser];
}

- (void)enableLog:(BOOL)enabelLog{
    [SALogger enableLog:enabelLog];
}

- (void)enableLog {
    BOOL printLog = NO;
#if (defined SENSORS_ANALYTICS_ENABLE_LOG)
    printLog = YES;
#endif
    
#if (defined SENSORS_ANALYTICS_DISABLE_LOG)
    printLog = NO;
#endif
    
    if ( [self debugMode] != SensorsAnalyticsDebugOff) {
        printLog = YES;
    }
    [SALogger enableLog:printLog];
}

- (NSString *)getSDKContollerUrl:(NSString *)urlString {
    NSString *retStr = nil;
    @try {
        if (urlString && [urlString isKindOfClass:NSString.class] && urlString.length){
            NSURLComponents *componets = [NSURLComponents componentsWithString:urlString];
            if (componets == nil) {
                SALog(@"URLString is malformed, nil is returned.");
                return nil;
            }
            componets.query = nil;
            componets.path = @"/config/iOS.conf";
            if (!self.remoteConfig.v) {
                componets.query = nil;
            } else {
                componets.query = [NSString stringWithFormat:@"v=%@",self.remoteConfig.v];
            }
            retStr = componets.URL.absoluteString;
        }
    } @catch (NSException *e) {
        retStr = nil;
        SAError(@"%@ error: %@", self, e);
    } @finally {
        return retStr;
    }
}

- (void)setSDKWithRemoteConfigDict:(NSDictionary *)configDict {
    @try {
        self.remoteConfig = [SASDKRemoteConfig configWithDict:configDict];
        if (self.remoteConfig.disableDebugMode) {
            [self disableDebugMode];
        }
    } @catch (NSException *e) {
        SAError(@"%@ error: %@", self, e);
    }
}

- (void)requestFunctionalManagermentConfig {
    @try {
        [self requestFunctionalManagermentConfigDelay:0 index:0];
    } @catch (NSException *e) {
        SAError(@"%@ error: %@", self, e);
    }
}

- (void)requestFunctionalManagermentConfigDelay:(NSTimeInterval) delay index:(NSUInteger) index {
    __weak typeof(self) weakself = self;
    void(^block)(BOOL success , NSDictionary *configDict) = ^(BOOL success , NSDictionary *configDict) {
        @try {
            if (success) {
                if(configDict != nil) {
                    //重新设置 config,处理 configDict 中的缺失参数
                    //用户没有配置远程控制选项，服务端默认返回{"disableSDK":false,"disableDebugMode":false}
                    NSString *v = [configDict valueForKey:@"v"];
                    NSNumber *disableSDK = [configDict valueForKeyPath:@"configs.disableSDK"];
                    NSNumber *disableDebugMode = [configDict valueForKeyPath:@"configs.disableDebugMode"];
                    NSNumber *autoTrackMode = [configDict valueForKeyPath:@"configs.autoTrackMode"];
                    //只在 disableSDK 由 false 变成 true 的时候发，主要是跟踪 SDK 关闭的情况。
                    if (disableSDK.boolValue == YES && weakself.remoteConfig.disableSDK == NO) {
                        [weakself track:@"DisableSensorsDataSDK" withProperties:@{}];
                    }
                    //如果有字段缺失，需要设置为默认值
                    if (disableSDK == nil) {
                        disableSDK = [NSNumber numberWithBool:NO];
                    }
                    if (disableDebugMode == nil) {
                        disableDebugMode = [NSNumber numberWithBool:NO];
                    }
                    if (autoTrackMode == nil) {
                        autoTrackMode = [NSNumber numberWithInteger:-1];
                    }
                    NSDictionary *configToBeSet = nil;
                    if (v) {
                        configToBeSet = @{@"v":v,@"configs":@{@"disableSDK":disableSDK,@"disableDebugMode":disableDebugMode,@"autoTrackMode":autoTrackMode}};
                    } else {
                        configToBeSet = @{@"configs":@{@"disableSDK":disableSDK,@"disableDebugMode":disableDebugMode,@"autoTrackMode":autoTrackMode}};
                    }
                    [[NSUserDefaults standardUserDefaults] setObject:configToBeSet forKey:@"SASDKConfig"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            } else {
                if (index < weakself.pullSDKConfigurationRetryMaxCount - 1) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakself requestFunctionalManagermentConfigDelay:30 index:index + 1];
                    });
                }
            }
        } @catch (NSException *e) {
            SAError(@"%@ error: %@", self, e);
        }
    };
    @try {
        self.reqConfigBlock = block;
        [self performSelector:@selector(requestFunctionalManagermentConfigWithCompletion:) withObject:self.reqConfigBlock afterDelay:delay inModes:@[NSRunLoopCommonModes,NSDefaultRunLoopMode]];
    } @catch (NSException *e) {
        SAError(@"%@ error: %@", self, e);
    }
}

- (void)requestFunctionalManagermentConfigWithCompletion:(void(^)(BOOL success, NSDictionary*configDict )) completion{
    @try {
        NSString *urlString = [self getSDKContollerUrl:self->_serverURL];
        if (urlString == nil || urlString.length == 0) {
            completion(NO,nil);
            return;
        }
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            @try{
                NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
                if (statusCode == 200) {
                    NSError *err = NULL;
                    NSDictionary *dict = nil;
                    if (data !=nil && data.length ) {
                        dict = [NSJSONSerialization  JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&err];
                    }
                    if (completion) {
                        completion(YES,dict);
                    }
                } else if (statusCode == 304) {
                    //304 config 没有更新
                    if (completion) {
                        completion(YES,nil);
                    }
                } else {
                    if (completion) {
                        completion(NO,nil);
                    }
                }
            } @catch (NSException *e) {
                SAError(@"%@ error: %@", self, e);
                if (completion) {
                    completion(NO,nil);
                }
            }
        }];
        [task resume];
    } @catch (NSException *e) {
        SAError(@"%@ error: %@", self, e);
    }
}

- (void)enableTrackScreenOrientation:(BOOL)enable {
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
    @try {
        self.deviceOrientationConfig.enableTrackScreenOrientation = enable;
        if (enable) {
            if (_deviceOrientationManager == nil) {
                _deviceOrientationManager = [[SADeviceOrientationManager alloc]init];
                __weak SensorsAnalyticsSDK *weakSelf = self;
                _deviceOrientationManager.deviceOrientationBlock = ^(NSString *deviceOrientation) {
                    __strong SensorsAnalyticsSDK *strongSelf = weakSelf;
                    if (deviceOrientation) {
                        strongSelf.deviceOrientationConfig.deviceOrientation = deviceOrientation;
                    }
                };
            }
            [_deviceOrientationManager startDeviceMotionUpdates];
        } else {
            _deviceOrientationConfig.deviceOrientation = @"";
            if (_deviceOrientationManager) {
                [_deviceOrientationManager stopDeviceMotionUpdates];
            }
        }
    } @catch (NSException * e) {
        SAError(@"%@ error: %@", self, e);
    }
#endif
}

- (void)enableTrackGPSLocation:(BOOL)enableGPSLocation {
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
    self.locationConfig.enableGPSLocation = enableGPSLocation;
    if (enableGPSLocation) {
        if (_locationManager == nil) {
            _locationManager = [[SALocationManager alloc]init];
            __weak SensorsAnalyticsSDK *weakSelf = self;
            _locationManager.updateLocationBlock = ^(CLLocation * location,NSError *error){
                __strong SensorsAnalyticsSDK *strongSelf = weakSelf;
                if (location) {
                    strongSelf.locationConfig.coordinate = location.coordinate;
                }
                if (error) {
                    SALog(@"%@",error);
                }
            };
        }
        [_locationManager startUpdatingLocation];
    }else{
        if (_locationManager != nil) {
            [_locationManager stopUpdatingLocation];
        }
    }
#endif
}

- (void)clearKeychainData {
    [SAKeyChainItemWrapper deletePasswordWithAccount:kSAUdidAccount service:kSAService];
    [SAKeyChainItemWrapper deletePasswordWithAccount:kSAAppInstallationAccount service:kSAService];
    [SAKeyChainItemWrapper deletePasswordWithAccount:kSAAppInstallationWithDisableCallbackAccount service:kSAService];
}

@end

#pragma mark - People analytics

@implementation SensorsAnalyticsPeople {
    __weak SensorsAnalyticsSDK *_sdk;
}

- (id)initWithSDK:(SensorsAnalyticsSDK *)sdk {
    self = [super init];
    if (self) {
        _sdk = sdk;
    }
    return self;
}

- (void)set:(NSDictionary *)profileDict {
    if (profileDict) {
        [_sdk track:nil withProperties:profileDict withType:@"profile_set"];
    }
}

- (void)setOnce:(NSDictionary *)profileDict {
    if (profileDict) {
        [_sdk track:nil withProperties:profileDict withType:@"profile_set_once"];
    }
}

- (void)set:(NSString *) profile to:(id)content {
    if (profile && content) {
        [_sdk track:nil withProperties:@{profile: content} withType:@"profile_set"];
    }
}

- (void)setOnce:(NSString *) profile to:(id)content {
    if (profile && content) {
        [_sdk track:nil withProperties:@{profile: content} withType:@"profile_set_once"];
    }
}

- (void)unset:(NSString *) profile {
    if (profile) {
        [_sdk track:nil withProperties:@{profile: @""} withType:@"profile_unset"];
    }
}

- (void)increment:(NSString *)profile by:(NSNumber *)amount {
    if (profile && amount) {
        [_sdk track:nil withProperties:@{profile: amount} withType:@"profile_increment"];
    }
}

- (void)increment:(NSDictionary *)profileDict {
    if (profileDict) {
        [_sdk track:nil withProperties:profileDict withType:@"profile_increment"];
    }
}

- (void)append:(NSString *)profile by:(NSSet *)content {
    if (profile && content) {
        [_sdk track:nil withProperties:@{profile: content} withType:@"profile_append"];
    }
}

- (void)deleteUser {
    [_sdk track:nil withProperties:@{} withType:@"profile_delete"];
}

@end
