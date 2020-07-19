//
// SARemoteConfigManager.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/7/16.
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

#import "SARemoteConfigManager.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAReadWriteLock.h"
#import "SAJSONUtil.h"
#import "SACommonUtility.h"
#import "SALog.h"

static NSString * const SA_SDK_TRACK_CONFIG = @"SASDKConfig";
///保存请求远程配置的随机时间 @{@"randomTime":@double,@“startDeviceTime”:@double}
static NSString * const SA_REQUEST_REMOTECONFIG_TIME = @"SARequestRemoteConfigRandomTime";

typedef void (^SARequestConfigBlock)(BOOL success, NSDictionary *configDict);

@interface SARemoteConfigManager ()

@property (nonatomic, strong) SARemoteConfigModel *remoteConfigModel;

@property (nonatomic, strong) SAReadWriteLock *remoteConfigLock;

@property (nonatomic, assign) NSUInteger requestRemoteConfigRetryMaxCount; // SDK 开启关闭功能接口最大重试次数

@property (nonatomic, copy) SARequestConfigBlock requestConfigBlock;

@end

@implementation SARemoteConfigManager

@synthesize remoteConfigModel = _remoteConfigModel;

#pragma mark - Life Cycle

+ (instancetype)sharedInstance {
    static SARemoteConfigManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SARemoteConfigManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *remoteConfigLockLabel = [NSString stringWithFormat:@"com.sensorsdata.remoteConfigLock.%p", self];
        _remoteConfigLock = [[SAReadWriteLock alloc] initWithQueueLabel:remoteConfigLockLabel];
        _requestRemoteConfigRetryMaxCount = 3;
    }
    return self;
}

#pragma mark - Public Methods

- (void)createLocalRemoteConfigModel {
    @try {
        NSDictionary *configDic = [[NSUserDefaults standardUserDefaults] objectForKey:SA_SDK_TRACK_CONFIG];
        self.remoteConfigModel = [[SARemoteConfigModel alloc] initWithDictionary:configDic];
        if (self.remoteConfigModel.mainConfigModel.disableDebugMode) {
            [[SensorsAnalyticsSDK sharedInstance] configServerURLWithDebugMode:SensorsAnalyticsDebugOff  showDebugModeWarning:NO];
        }
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)shouldRequestRemoteConfig {
    // 触发远程配置请求的五个条件
    // 1. 判断是否禁用分散请求，如果禁用则直接请求，同时将本地存储的随机时间清除
    if ([SensorsAnalyticsSDK sharedInstance].configOptions.disableRandomTimeRequestRemoteConfig ||
        [SensorsAnalyticsSDK sharedInstance].configOptions.maxRequestHourInterval < [SensorsAnalyticsSDK sharedInstance].configOptions.minRequestHourInterval) {
        [self requestRemoteConfigWithRemoveRandomTimeFlag:YES];
        SALogDebug(@"Request remote config because disableRandomTimerequestRemoteConfig or minHourInterval and maxHourInterval error，Please check the value");
        return;
    }
    
    // 2. 如果 SDK 版本变化，则强制请求远程配置，同时本地生成随机时间
    if (![self isLibVersionEqualToSDK]) {
        [self requestRemoteConfigWithRemoveRandomTimeFlag:NO];
        SALogDebug(@"Request remote config because SDK version is changed");
        return;
    }
    
    // 3. 如果开启加密并且未设置公钥（新用户安装或者从未加密版本升级而来），则请求远程配置获取公钥，同时本地生成随机时间
#ifdef SENSORS_ANALYTICS_ENABLE_ENCRYPTION
    if (![SensorsAnalyticsSDK sharedInstance].encryptBuilder) {
        [self requestRemoteConfigWithRemoveRandomTimeFlag:NO];
        SALogDebug(@"Request remote config because encrypt builder is nil");
        return;
    }
#endif
    
    // 获取本地保存的随机时间和设备启动时间
    NSDictionary *requestTimeConfig = [[NSUserDefaults standardUserDefaults] objectForKey:SA_REQUEST_REMOTECONFIG_TIME];
    double randomTime = [[requestTimeConfig objectForKey:@"randomTime"] doubleValue];
    double startDeviceTime = [[requestTimeConfig objectForKey:@"startDeviceTime"] doubleValue];
    // 获取当前设备启动时间，以开机时间为准，单位：秒
    NSTimeInterval currentTime = NSProcessInfo.processInfo.systemUptime;
    
    // 4. 如果设备重启过，则强制请求远程配置，同时本地生成随机时间
    if (currentTime < startDeviceTime) {
        [self requestRemoteConfigWithRemoveRandomTimeFlag:NO];
        SALogDebug(@"Request remote config because the device has been restarted");
        return;
    }
    
    // 5. 满足分散请求的条件，则请求远程配置，同时本地生成随机时间
    if (currentTime >= randomTime) {
        [self requestRemoteConfigWithRemoveRandomTimeFlag:NO];
        SALogDebug(@"Request remote config because satisfy the random request condition");
    }
}

- (void)retryRequestRemoteConfig {
    [self cancelRequestRemoteConfig];
    [self requestRemoteConfigWithRemoveRandomTimeFlag:NO];
}

- (void)requestRemoteConfigWithRemoveRandomTimeFlag:(BOOL)isRemoveRandomTime {
    @try {
        [self requestRemoteConfigWithDelay:0 index:0];
        isRemoveRandomTime ? [self removeRandomTime] : [self createRandomTime];
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)cancelRequestRemoteConfig {
    if (self.requestConfigBlock) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestRemoteConfigWithCompletion:) object:self.requestConfigBlock];
        self.requestConfigBlock = nil;
    }
}

#pragma mark – Private Methods

- (void)createRandomTime {
    // 当前时间，以开机时间为准，单位：秒
    NSTimeInterval currentTime = NSProcessInfo.processInfo.systemUptime;
    
    // 计算实际间隔时间（此时只需要考虑 minRequestHourInterval <= maxRequestHourInterval 的情况）
    double realIntervalTime = [SensorsAnalyticsSDK sharedInstance].configOptions.minRequestHourInterval * 60 * 60;
    if ([SensorsAnalyticsSDK sharedInstance].configOptions.maxRequestHourInterval > [SensorsAnalyticsSDK sharedInstance].configOptions.minRequestHourInterval) {
        // 转换成 秒 再取随机时间
        double durationSecond = ([SensorsAnalyticsSDK sharedInstance].configOptions.maxRequestHourInterval - [SensorsAnalyticsSDK sharedInstance].configOptions.minRequestHourInterval) * 60 * 60;
        
        // arc4random_uniform 的取值范围，是左闭右开，所以 +1
        realIntervalTime += arc4random_uniform(durationSecond + 1);
    }
    
    // 触发请求后，生成下次随机触发时间
    double randomTime = currentTime + realIntervalTime;
    
    NSDictionary *createRequestTimeConfig = @{ @"randomTime": @(randomTime), @"startDeviceTime": @(currentTime) };
    [[NSUserDefaults standardUserDefaults] setObject:createRequestTimeConfig forKey:SA_REQUEST_REMOTECONFIG_TIME];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeRandomTime {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SA_REQUEST_REMOTECONFIG_TIME];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isLibVersionEqualToSDK {
    return [self.remoteConfigModel.localLibVersion isEqualToString:[[SensorsAnalyticsSDK sharedInstance] libVersion]];
}

- (void)requestRemoteConfigWithDelay:(NSTimeInterval) delay index:(NSUInteger) index {
    __weak typeof(self) weakself = self;
    void(^block)(BOOL success , NSDictionary *configDict) = ^(BOOL success , NSDictionary *configDict) {
        @try {
            if (success) {
                if(configDict != nil) {
                    // 远程配置
                    [self dealWithRemoteConfigWithRequestResult:configDict];
                    
                    // 加密相关内容
                    NSDictionary *publicKeyDic = [configDict valueForKeyPath:@"configs.key"];
                    if (publicKeyDic) {
                        SASecretKey *secreKey = [[SASecretKey alloc] init];
                        secreKey.version = [publicKeyDic[@"pkv"] integerValue];
                        secreKey.key = publicKeyDic[@"public_key"];
                        
                        [[SensorsAnalyticsSDK sharedInstance] loadSecretKey:secreKey];
                        if ([SensorsAnalyticsSDK sharedInstance].saveSecretKeyCompletion) {
                            [SensorsAnalyticsSDK sharedInstance].saveSecretKeyCompletion(secreKey);
                        }
                    }
                }
            } else {
                if (index < weakself.requestRemoteConfigRetryMaxCount - 1) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakself requestRemoteConfigWithDelay:30 index:index + 1];
                    });
                }
            }
        } @catch (NSException *e) {
            SALogError(@"%@ error: %@", self, e);
        }
    };
    @try {
        self.requestConfigBlock = block;
        [self performSelector:@selector(requestRemoteConfigWithCompletion:) withObject:self.requestConfigBlock afterDelay:delay inModes:@[NSRunLoopCommonModes, NSDefaultRunLoopMode]];
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)requestRemoteConfigWithCompletion:(void(^)(BOOL success, NSDictionary*configDict )) completion{
    @try {
        NSString *networkTypeString = [SACommonUtility currentNetworkStatus];
        SensorsAnalyticsNetworkType networkType = [[SensorsAnalyticsSDK sharedInstance] toNetworkType:networkTypeString];
        if (networkType == SensorsAnalyticsNetworkTypeNONE) {
            completion(NO, nil);
            return;
        }
        NSURL *url = [NSURL URLWithString:[SensorsAnalyticsSDK sharedInstance].configOptions.remoteConfigURL];
        
        BOOL shouldAddVersion = [self isLibVersionEqualToSDK];
#ifdef SENSORS_ANALYTICS_ENABLE_ENCRYPTION
        shouldAddVersion = shouldAddVersion && [SensorsAnalyticsSDK sharedInstance].encryptBuilder;
#endif
        NSString *mainConfigVersion = shouldAddVersion ? self.remoteConfigModel.version : nil;
        NSString *eventConfigVersion = shouldAddVersion ? self.eventConfigModel.version : nil;
        [[SensorsAnalyticsSDK sharedInstance].network functionalManagermentConfigWithRemoteConfigURL:url mainConfigVersion:mainConfigVersion eventConfigVersion:eventConfigVersion completion:completion];
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)dealWithRemoteConfigWithRequestResult:(NSDictionary *)configDict {
    // 重新设置 config,处理 configDict 中的缺失参数
    // 用户没有配置远程控制选项，服务端默认返回{"disableSDK":false,"disableDebugMode":false}
    SARemoteConfigModel *remoteConfigModel = [[SARemoteConfigModel alloc] initWithDictionary:configDict];
    
    // 只在 disableSDK 由 false 变成 true 的时候发，主要是跟踪 SDK 关闭的情况。
    if (remoteConfigModel.mainConfigModel.disableSDK == YES && self.mainConfigModel.disableSDK == NO) {
        [[SensorsAnalyticsSDK sharedInstance] track:@"DisableSensorsDataSDK" withProperties:@{} withTrackType:SensorsAnalyticsTrackTypeAuto];
    }
    
    // 只在 event_config 的 v 改变的时候触发远程配置事件
    if (![remoteConfigModel.eventConfigModel.version isEqualToString:self.eventConfigModel.version]) {
        NSString *eventConfigStr = @"";
        NSDictionary *eventConfigDic = [remoteConfigModel.eventConfigModel toDictionary];
        NSData *eventConfigData = [[[SAJSONUtil alloc] init] JSONSerializeObject:eventConfigDic];
        if (eventConfigData) {
            eventConfigStr = [[NSString alloc] initWithData:eventConfigData encoding:NSUTF8StringEncoding];
        }
        
        [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_REMOTE_CONFIG_CHANGED withProperties:@{SA_EVENT_PROPERTY_APP_REMOTE_CONFIG : eventConfigStr} withTrackType:SensorsAnalyticsTrackTypeAuto];
    }
    
    NSMutableDictionary *localStoreConfig = [NSMutableDictionary dictionaryWithDictionary:[remoteConfigModel toDictionary]];
    // 存储当前 SDK 版本号
    localStoreConfig[@"localLibVersion"] = [[SensorsAnalyticsSDK sharedInstance] libVersion];
    [[NSUserDefaults standardUserDefaults] setObject:localStoreConfig forKey:SA_SDK_TRACK_CONFIG];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 事件黑名单要立即生效
    self.remoteConfigModel.eventConfigModel = remoteConfigModel.eventConfigModel;
}

#pragma mark – Getters and Setters

- (void)setRemoteConfigModel:(SARemoteConfigModel *)remoteConfigModel {
    [self.remoteConfigLock writeWithBlock:^{
        self->_remoteConfigModel = remoteConfigModel;
    }];
}

- (SARemoteConfigModel *)remoteConfigModel {
    return [self.remoteConfigLock readWithBlock:^id _Nonnull{
        return self->_remoteConfigModel;
    }];
}

- (SARemoteMainConfigModel *)mainConfigModel {
    return self.remoteConfigModel.mainConfigModel;
}

- (SARemoteEventConfigModel *)eventConfigModel {
    return self.remoteConfigModel.eventConfigModel;
}

@end
