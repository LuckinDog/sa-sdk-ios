//
// SARemoteConfigManager.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/7/20.
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
#import "SAConstants+Private.h"
#import "SAReadWriteLock.h"
#import "SAJSONUtil.h"
#import "SACommonUtility.h"
#import "SALog.h"

@implementation SARemoteConfigManagerOptions

@end

typedef NS_ENUM(NSInteger, SARemoteConfigHandleRandomTimeType) {
    SARemoteConfigHandleRandomTimeTypeCreate, // 创建分散请求时间
    SARemoteConfigHandleRandomTimeTypeRemove, // 移除分散请求时间
    SARemoteConfigHandleRandomTimeTypeNone    // 不处理分散请求时间
};

static NSString * const SA_SDK_TRACK_CONFIG = @"SASDKConfig";
///保存请求远程配置的随机时间 @{@"randomTime":@double,@“startDeviceTime”:@double}
static NSString * const SA_REQUEST_REMOTECONFIG_TIME = @"SARequestRemoteConfigRandomTime";

static SARemoteConfigManager *sharedInstance = nil;
static dispatch_once_t initializeOnceToken;

@interface SARemoteConfigManager ()

@property (nonatomic, strong) SARemoteConfigModel *remoteConfigModel;

@property (nonatomic, strong) SAReadWriteLock *remoteConfigLock;

@property (nonatomic, assign) NSUInteger requestRemoteConfigRetryMaxCount; // SDK 开启关闭功能接口最大重试次数

@property (nonatomic, strong) SARemoteConfigManagerOptions *managerOptions;

@property (nonatomic, strong) NSURLSessionTask *currentNetworkTask;

@property (nonatomic, copy) NSDictionary *requestRemoteConfigParams;

@end

@implementation SARemoteConfigManager

@synthesize remoteConfigModel = _remoteConfigModel;

#pragma mark - Life Cycle

+ (void)startWithRemoteConfigManagerOptions:(SARemoteConfigManagerOptions *)managerOptions {
    dispatch_once(&initializeOnceToken, ^{
        sharedInstance = [[SARemoteConfigManager alloc] initWithManagerOptions:managerOptions];
    });
}

+ (SARemoteConfigManager *_Nullable)sharedInstance {
    return sharedInstance;
}

- (instancetype)initWithManagerOptions:(SARemoteConfigManagerOptions *)managerOptions {
    self = [super init];
    if (self) {
        _managerOptions = managerOptions;
        
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
        if (self.remoteConfigModel.mainConfigModel.disableDebugMode && self.managerOptions.disableDebugModeBlock) {
            self.managerOptions.disableDebugModeBlock();
        }
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)shouldRequestRemoteConfig {
    // 触发远程配置请求的四个条件
    // 1. 判断是否禁用分散请求，如果禁用则直接请求，同时将本地存储的随机时间清除
    if (self.managerOptions.configOptions.disableRandomTimeRequestRemoteConfig || self.managerOptions.configOptions.maxRequestHourInterval < self.managerOptions.configOptions.minRequestHourInterval) {
        [self requestRemoteConfigWithHandleRandomTimeType:SARemoteConfigHandleRandomTimeTypeRemove isForceUpdate:NO];
        SALogDebug(@"Request remote config because disableRandomTimerequestRemoteConfig or minHourInterval and maxHourInterval error，Please check the value");
        return;
    }
    
    // 2. 如果开启加密并且未设置公钥（新用户安装或者从未加密版本升级而来），则请求远程配置获取公钥，同时本地生成随机时间
    if (self.managerOptions.configOptions.enableEncrypt) {
        if (!self.managerOptions.encryptBuilderCreateResultBlock || !self.managerOptions.encryptBuilderCreateResultBlock()) {
            [self requestRemoteConfigWithHandleRandomTimeType:SARemoteConfigHandleRandomTimeTypeCreate isForceUpdate:NO];
            SALogDebug(@"Request remote config because encrypt builder is nil");
            return;
        }
    }
    
    // 获取本地保存的随机时间和设备启动时间
    NSDictionary *requestTimeConfig = [[NSUserDefaults standardUserDefaults] objectForKey:SA_REQUEST_REMOTECONFIG_TIME];
    double randomTime = [[requestTimeConfig objectForKey:@"randomTime"] doubleValue];
    double startDeviceTime = [[requestTimeConfig objectForKey:@"startDeviceTime"] doubleValue];
    // 获取当前设备启动时间，以开机时间为准，单位：秒
    NSTimeInterval currentTime = NSProcessInfo.processInfo.systemUptime;
    
    // 3. 如果设备重启过，则强制请求远程配置，同时本地生成随机时间
    if (currentTime < startDeviceTime) {
        [self requestRemoteConfigWithHandleRandomTimeType:SARemoteConfigHandleRandomTimeTypeCreate isForceUpdate:NO];
        SALogDebug(@"Request remote config because the device has been restarted");
        return;
    }
    
    // 4. 满足分散请求的条件，则请求远程配置，同时本地生成随机时间
    if (currentTime >= randomTime) {
        [self requestRemoteConfigWithHandleRandomTimeType:SARemoteConfigHandleRandomTimeTypeCreate isForceUpdate:NO];
        SALogDebug(@"Request remote config because satisfy the random request condition");
    }
}

- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate {
    [self cancelRequestRemoteConfig];
    [self requestRemoteConfigWithHandleRandomTimeType:SARemoteConfigHandleRandomTimeTypeCreate isForceUpdate:isForceUpdate];
}

- (void)requestRemoteConfigWithHandleRandomTimeType:(SARemoteConfigHandleRandomTimeType)type isForceUpdate:(BOOL)isForceUpdate {
    @try {
        [self requestRemoteConfigWithDelay:0 index:0 isForceUpdate:isForceUpdate];
        
        switch (type) {
            case SARemoteConfigHandleRandomTimeTypeCreate:
                [self createRandomTime];
                break;
                
            case SARemoteConfigHandleRandomTimeTypeRemove:
                [self removeRandomTime];
                break;
                
            default:
                break;
        }
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)cancelRequestRemoteConfig {
    [SACommonUtility performAsyncBlockOnMainThread:^{
        // 还未发出请求
        if (self.requestRemoteConfigParams) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestRemoteConfigWithParams:) object:self.requestRemoteConfigParams];
            self.requestRemoteConfigParams = nil;
        }
        
        // 已经发出请求
        [self.currentNetworkTask cancel];
    }];
}

#pragma mark – Private Methods

- (void)createRandomTime {
    // 当前时间，以开机时间为准，单位：秒
    NSTimeInterval currentTime = NSProcessInfo.processInfo.systemUptime;
    
    // 计算实际间隔时间（此时只需要考虑 minRequestHourInterval <= maxRequestHourInterval 的情况）
    double realIntervalTime = self.managerOptions.configOptions.minRequestHourInterval * 60 * 60;
    if (self.managerOptions.configOptions.maxRequestHourInterval > self.managerOptions.configOptions.minRequestHourInterval) {
        // 转换成 秒 再取随机时间
        double durationSecond = (self.managerOptions.configOptions.maxRequestHourInterval - self.managerOptions.configOptions.minRequestHourInterval) * 60 * 60;
        
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

- (BOOL)isLibVersionUnchanged {
    return [self.remoteConfigModel.localLibVersion isEqualToString:self.managerOptions.currentLibVersion];
}

- (BOOL)isCreateEncryptBuilder {
    if (self.managerOptions.encryptBuilderCreateResultBlock) {
        return self.managerOptions.encryptBuilderCreateResultBlock();
    }
    return NO;
}

- (void)requestRemoteConfigWithDelay:(NSTimeInterval) delay index:(NSUInteger) index isForceUpdate:(BOOL)isForceUpdate {
    __weak typeof(self) weakSelf = self;
    void(^completion)(BOOL success, NSDictionary<NSString *, id> *config, NSError * _Nullable error) = ^(BOOL success, NSDictionary<NSString *, id> *config, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        @try {
            if (error.code == -999) {
                // 主动 cancel task 的情况，不重试远程配置请求
                return;
            }
            
            if (success) {
                if(config != nil) {
                    // 远程配置
                    [strongSelf handleRemoteConfigWithRequestResult:config];
                    
                    // 加密
                    if (strongSelf.managerOptions.configOptions.enableEncrypt && strongSelf.managerOptions.handleSecretKeyBlock) {
                        strongSelf.managerOptions.handleSecretKeyBlock(config);
                    }
                }
            } else {
                if (index < strongSelf.requestRemoteConfigRetryMaxCount - 1) {
                    [strongSelf requestRemoteConfigWithDelay:30 index:index + 1 isForceUpdate:isForceUpdate];
                }
            }
        } @catch (NSException *e) {
            SALogError(@"%@ error: %@", strongSelf, e);
        }
    };
    
    @try {
        // 在子线程中，有 afterDelay 参数的方法不会被执行
        [SACommonUtility performAsyncBlockOnMainThread:^{
            self.requestRemoteConfigParams = @{@"isForceUpdate" : @(isForceUpdate), @"completion" : completion};
            [self performSelector:@selector(requestRemoteConfigWithParams:) withObject:self.requestRemoteConfigParams afterDelay:delay inModes:@[NSRunLoopCommonModes, NSDefaultRunLoopMode]];
        }];
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)requestRemoteConfigWithParams:(NSDictionary *)params {
    @try {
        BOOL isForceUpdate = [params[@"isForceUpdate"] boolValue];
        void(^completion)(BOOL success, NSDictionary<NSString *, id> *config, NSError * _Nullable error) = params[@"completion"];
        
        NSString *networkTypeString = [SACommonUtility currentNetworkStatus];
        SensorsAnalyticsNetworkType networkType = [SACommonUtility toNetworkType:networkTypeString];
        if (networkType == SensorsAnalyticsNetworkTypeNONE) {
            completion(NO, nil, nil);
            return;
        }
        NSURL *url = [NSURL URLWithString:self.managerOptions.configOptions.remoteConfigURL];
        
        BOOL shouldAddVersion = !isForceUpdate;
        shouldAddVersion = shouldAddVersion && [self isLibVersionUnchanged];
        if (self.managerOptions.configOptions.enableEncrypt) {
            shouldAddVersion = shouldAddVersion && [self isCreateEncryptBuilder];
        }
        
        NSString *mainConfigVersion = shouldAddVersion ? self.remoteConfigModel.version : nil;
        NSString *eventConfigVersion = shouldAddVersion ? self.eventConfigModel.version : nil;
        self.currentNetworkTask = [self.managerOptions.network functionalManagermentConfigWithRemoteConfigURL:url mainConfigVersion:mainConfigVersion eventConfigVersion:eventConfigVersion completion:completion];
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)handleRemoteConfigWithRequestResult:(NSDictionary *)configDict {
    // 重新设置 config,处理 configDict 中的缺失参数
    // 用户没有配置远程控制选项，服务端默认返回{"disableSDK":false,"disableDebugMode":false}
    SARemoteConfigModel *remoteConfigModel = [[SARemoteConfigModel alloc] initWithDictionary:configDict];
    
    // 只在 disableSDK 由 false 变成 true 的时候发，主要是跟踪 SDK 关闭的情况。
    if (remoteConfigModel.mainConfigModel.disableSDK == YES && self.mainConfigModel.disableSDK == NO) {
        if (self.managerOptions.trackEventBlock) {
            self.managerOptions.trackEventBlock(@"DisableSensorsDataSDK", @{});
        }
    }
    
    // 只在 event_config 的 v 改变的时候触发远程配置事件
    if (![remoteConfigModel.eventConfigModel.version isEqualToString:self.eventConfigModel.version]) {
        NSString *eventConfigStr = @"";
        NSData *eventConfigData = [[[SAJSONUtil alloc] init] JSONSerializeObject:[remoteConfigModel.eventConfigModel toDictionary]];
        if (eventConfigData) {
            eventConfigStr = [[NSString alloc] initWithData:eventConfigData encoding:NSUTF8StringEncoding];
        }
        
        if (self.managerOptions.trackEventBlock) {
            self.managerOptions.trackEventBlock(SA_EVENT_NAME_APP_REMOTE_CONFIG_CHANGED, @{SA_EVENT_PROPERTY_APP_REMOTE_CONFIG : eventConfigStr});
        }        
    }
    
    NSMutableDictionary *localStoreConfig = [NSMutableDictionary dictionaryWithDictionary:[remoteConfigModel toDictionary]];
    // 存储当前 SDK 版本号
    localStoreConfig[@"localLibVersion"] = self.managerOptions.currentLibVersion;
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

