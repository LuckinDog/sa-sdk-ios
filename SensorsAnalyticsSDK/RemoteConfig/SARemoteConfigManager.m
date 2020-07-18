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
#ifdef SENSORS_ANALYTICS_ENABLE_ENCRYPTION
    // 如果开启加密，并且未设置公钥（新用户安装或者从未加密版本升级而来），需要及时请求一次远程配置，获取公钥。
    if (![SensorsAnalyticsSDK sharedInstance].encryptBuilder) {
        [self requestRemoteConfig];
        [self createRandomTime];
        return;
    }
#endif
    
    // 判断是否符合分散 remoteconfig 请求条件
    if ([SensorsAnalyticsSDK sharedInstance].configOptions.disableRandomTimeRequestRemoteConfig ||
        [SensorsAnalyticsSDK sharedInstance].configOptions.maxRequestHourInterval < [SensorsAnalyticsSDK sharedInstance].configOptions.minRequestHourInterval) {
        [self requestRemoteConfig];
        SALogDebug(@"disableRandomTimerequestRemoteConfig or minHourInterval and maxHourInterval error，Please check the value");
        return;
    }
    
    NSDictionary *requestTimeConfig = [[NSUserDefaults standardUserDefaults] objectForKey:SA_REQUEST_REMOTECONFIG_TIME];
    double randomTime = [[requestTimeConfig objectForKey:@"randomTime"] doubleValue];
    double startDeviceTime = [[requestTimeConfig objectForKey:@"startDeviceTime"] doubleValue];
    // 当前时间，以开机时间为准，单位：秒
    NSTimeInterval currentTime = NSProcessInfo.processInfo.systemUptime;
    
    // 不满足触发条件
    if (currentTime >= startDeviceTime && currentTime < randomTime) {
        return;
    }
    [self requestRemoteConfig];
    [self createRandomTime];
}

- (void)retryRequestRemoteConfig {
    [self cancelRequestRemoteConfig];
    [self requestRemoteConfig];
}

- (void)requestRemoteConfig {
    @try {
        [self requestRemoteConfigWithDelay:0 index:0];
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
    
    // 触发请求后，再次生成下次随机触发时间
    double createRandomTime = [SensorsAnalyticsSDK sharedInstance].configOptions.minRequestHourInterval * 60 * 60;
    if ([SensorsAnalyticsSDK sharedInstance].configOptions.maxRequestHourInterval > [SensorsAnalyticsSDK sharedInstance].configOptions.minRequestHourInterval) {
        // 转换成 秒 再取随机时间
        double durationSecond = ([SensorsAnalyticsSDK sharedInstance].configOptions.maxRequestHourInterval - [SensorsAnalyticsSDK sharedInstance].configOptions.minRequestHourInterval) * 60 * 60;
        
        // arc4random_uniform 的取值范围，是左闭右开，所以 +1
        createRandomTime += arc4random_uniform(durationSecond + 1);
    }
    NSDictionary *createRequestTimeConfig = @{ @"randomTime": @(createRandomTime), @"startDeviceTime": @(currentTime) };
    [[NSUserDefaults standardUserDefaults] setObject:createRequestTimeConfig forKey:SA_REQUEST_REMOTECONFIG_TIME];
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
        
        BOOL shouldAddVersion = [self isLibVersionEqualToSDK] && [SensorsAnalyticsSDK sharedInstance].encryptBuilder;
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
