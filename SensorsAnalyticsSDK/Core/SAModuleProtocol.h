//
//  SAModuleProtocol.h
//  Pods
//
//  Created by 张敏超🍎 on 2020/8/12.
//  
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import "SAConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class SASecretKey;
@class SAConfigOptions;

@protocol SAModuleProtocol <NSObject>

- (instancetype)init;

@property (nonatomic, assign, getter=isEnable) BOOL enable;

@optional

@property (nonatomic, strong) SAConfigOptions *configOptions;

@end

#pragma mark -

@protocol SAPropertyModuleProtocol <SAModuleProtocol>

@property (nonatomic, copy, readonly, nullable) NSDictionary *properties;

@end

#pragma mark -

@protocol SAOpenURLProtocol <NSObject>

- (BOOL)canHandleURL:(NSURL *)url;
- (BOOL)handleURL:(NSURL *)url;

@end

#pragma mark -

@protocol SAChannelMatchModuleProtocol <NSObject>

/**
 * @abstract
 * 用于在 App 首次启动时追踪渠道来源，并设置追踪渠道事件的属性。SDK 会将渠道值填入事件属性 $utm_ 开头的一系列属性中。
 *
 * @param event  event 的名称
 * @param properties     event 的属性
 * @param disableCallback     是否关闭这次渠道匹配的回调请求
*/
- (void)trackAppInstall:(NSString *)event properties:(NSDictionary *)properties disableCallback:(BOOL)disableCallback;

@end

#pragma mark -

@protocol SADebugModeModuleProtocol <NSObject>

/// Debug Mode 属性，设置或获取 Debug 模式
@property (nonatomic) SensorsAnalyticsDebugMode debugMode;

/// 设置在 Debug 模式下，是否弹窗显示错误信息
/// @param isShow 是否显示
- (void)setShowDebugAlertView:(BOOL)isShow;

/// 设置 SDK 的 DebugMode 在 Debug 模式时弹窗警告
/// @param mode Debug 模式
- (void)handleDebugMode:(SensorsAnalyticsDebugMode)mode;

/// Debug 模式下，弹窗显示错误信息
/// @param message 错误信息
- (void)showDebugModeWarning:(NSString *)message;

@end

#pragma mark -

@protocol SAEncryptModuleProtocol <NSObject>

@property (nonatomic, readonly) BOOL hasSecretKey;

/// 用于远程配置回调中处理并保存密钥
/// @param encryptConfig 返回的
- (void)handleEncryptWithConfig:(NSDictionary *)encryptConfig;

/// 加密数据
/// @param obj 需要加密的 JSON 数据
/// @return 返回加密后的数据
- (nullable NSDictionary *)encryptJSONObject:(id)obj;

@end

@protocol SAAppPushModuleProtocol <NSObject>

- (void)setLaunchOptions:(NSDictionary *)launchOptions;

@end

#pragma mark -

@protocol SAGestureModuleProtocol <NSObject>

/// 校验可视化全埋点元素能否选中
/// @param obj 控件元素
/// @return 返回校验结果
- (BOOL)isGestureVisualView:(id)obj;

@end

#pragma mark -

@protocol SADeeplinkModuleProtocol <NSObject>

/// DeepLink 回调函数
/// @param linkHandlerCallback  callback 请求成功后的回调函数
///     - params：创建渠道链接时填写的 App 内参数
///     - succes：deeplink 唤起结果
///     - appAwakePassedTime：获取渠道信息所用时间
- (void)setLinkHandlerCallback:(void (^ _Nonnull)(NSString * _Nullable, BOOL, NSInteger))linkHandlerCallback;

/// 最新的来源渠道信息
@property (nonatomic, copy, nullable, readonly) NSDictionary *latestUtmProperties;

/// 当前 DeepLink 启动时的来源渠道信息
@property (nonatomic, copy, readonly) NSDictionary *utmProperties;

/// 清除本次 DeepLink 解析到的 utm 信息
- (void)clearUtmProperties;

@end

#pragma mark -

@protocol SATrackTimerModuleProtocol <NSObject>

#pragma mark - generate event id
/**
 @abstract
 生成事件计时的 eventId

 @param eventName 开始计时的事件名
 @return 计时事件的 eventId
*/
- (NSString *)generateEventIdByEventName:(NSString *)eventName;

#pragma mark - track timer for event
/**
 @abstract
 开始事件计时

 @discussion
 多次调用 trackTimerStart: 时，以最后一次调用为准。

 @param eventId 开始计时的事件名或 eventId
*/
- (void)trackTimerStart:(NSString *)eventId currentSysUpTime:(UInt64)currentSysUpTime;

/**
 @abstract
 为了兼容废弃接口功能提供 timeUnit 入参

 @param eventId 开始计时的事件名或 eventId
 @param timeUnit 计时单位，毫秒/秒/分钟/小时
*/
- (void)trackTimerStart:(NSString *)eventId timeUnit:(SensorsAnalyticsTimeUnit)timeUnit currentSysUpTime:(UInt64)currentSysUpTime;

/**
 @abstract
 暂停事件计时

 @discussion
 多次调用 trackTimerPause: 时，以首次调用为准。

 @param eventId  trackTimerStart: 返回的 ID 或事件名
*/
- (void)trackTimerPause:(NSString *)eventId currentSysUpTime:(UInt64)currentSysUpTime;

/**
 @abstract
 恢复事件计时

 @discussion
 多次调用 trackTimerResume: 时，以首次调用为准。

 @param eventId trackTimerStart: 返回的 ID 或事件名
*/
- (void)trackTimerResume:(NSString *)eventId currentSysUpTime:(UInt64)currentSysUpTime;

/**
 @abstract
 删除事件计时

 @discussion
 多次调用 trackTimerRemove: 时，只有首次调用有效。

 @param eventId trackTimerStart: 返回的 ID 或事件名
*/
- (void)trackTimerRemove:(NSString *)eventId;

#pragma mark -
/**
 @abstract
 获取事件时长

 @param eventId trackTimerStart: 返回的 ID 或事件名
 @param currentSysUpTime 当前系统启动时间

 @return 计时事件的时长
*/
- (nullable NSNumber *)eventDurationFromEventId:(NSString *)eventId currentSysUpTime:(UInt64)currentSysUpTime;

/**
 @abstract
 获取计时事件原始事件名

 @param eventId trackTimerStart: 返回的 ID 或事件名
 @return 计时事件的原始事件名
*/
- (NSString *)eventNameFromEventId:(NSString *)eventId;

#pragma mark - operation all timing events
/**
 @abstract
 暂停所有计时事件
*/
- (void)pauseAllEventTimers:(UInt64)currentSysUpTime;

/**
 @abstract
 恢复所有计时事件
*/
- (void)resumeAllEventTimers:(UInt64)currentSysUpTime;

/**
 @abstract
 清除所有计时事件
*/
- (void)clearAllEventTimers;

@end

NS_ASSUME_NONNULL_END
