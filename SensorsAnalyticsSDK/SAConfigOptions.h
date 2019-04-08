//
//  SAConfigOptions.h
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2019/4/8.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAConstants.h"

NS_ASSUME_NONNULL_BEGIN


/**
 * @class
 *  SensorsAnalyticsSDK 初始化配置
 */
@interface SAConfigOptions : NSObject

/**
 指定初始化方法，设置 serverURL
 
 @param serverUrl 数据接收地址
 @return 配置对象
 */
- (instancetype)initWithServerURL:(nonnull NSString *)serverURL launchOptions:(nullable NSDictionary *)launchOptions NS_DESIGNATED_INITIALIZER;

/**
 禁用 init 初始化
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 禁用 new 初始化
 */
+ (instancetype)new NS_UNAVAILABLE;

/**
 请求配置地址，默认从 ServerUrl 解析
 */
@property(nonatomic, copy) NSString *remoteConfigURL;

/**
 * @property
 *
 * @abstract
 * 打开 SDK 自动追踪,默认只追踪 App 启动 / 关闭、进入页面、元素点击
 *
 * @discussion
 * 该功能自动追踪 App 的一些行为，例如 SDK 初始化、App 启动 / 关闭、进入页面 等等，具体信息请参考文档:
 *   https://sensorsdata.cn/manual/ios_sdk.html
 * 该功能默认关闭
 */
@property(nonatomic) SensorsAnalyticsAutoTrackEventType eventType;

/**
 * @abstract
 * 是否自动收集 App Crash 日志，该功能默认是关闭的
 */
@property(nonatomic) BOOL enableTrackAppCrash;

/**
 * @property
 *
 * @abstract
 * 两次数据发送的最小时间间隔，单位毫秒
 *
 * @discussion
 * 默认值为 15 * 1000 毫秒， 在每次调用 track、trackSignUp 以及 profileSet 等接口的时候，
 * 都会检查如下条件，以判断是否向服务器上传数据:
 * 1. 是否 WIFI/3G/4G 网络
 * 2. 是否满足以下数据发送条件之一:
 *   1) 与上次发送的时间间隔是否大于 flushInterval
 *   2) 本地缓存日志数目是否达到 flushBulkSize
 * 如果满足这两个条件之一，则向服务器发送一次数据；如果都不满足，则把数据加入到队列中，等待下次检查时把整个队列的内容一并发送。
 * 需要注意的是，为了避免占用过多存储，队列最多只缓存10000条数据。
 */
@property (atomic) UInt64 flushInterval;

/**
 * @property
 *
 * @abstract
 * 本地缓存的最大事件数目，当累积日志量达到阈值时发送数据
 *
 * @discussion
 * 默认值为 100，在每次调用 track、trackSignUp 以及 profileSet 等接口的时候，都会检查如下条件，以判断是否向服务器上传数据:
 * 1. 是否 WIFI/3G/4G 网络
 * 2. 是否满足以下数据发送条件之一:
 *   1) 与上次发送的时间间隔是否大于 flushInterval
 *   2) 本地缓存日志数目是否达到 flushBulkSize
 * 如果同时满足这两个条件，则向服务器发送一次数据；如果不满足，则把数据加入到队列中，等待下次检查时把整个队列的内容一并发送。
 * 需要注意的是，为了避免占用过多存储，队列最多只缓存 10000 条数据。
 */
@property (atomic) UInt64 flushBulkSize;

/**
 * @abstract
 * 设置本地缓存最多事件条数
 *
 * @discussion
 * 默认为 10000 条事件
 *
 * @param maxCacheSize 本地缓存最多事件条数
 */
@property (atomic) UInt64 maxCacheSize;

@end

NS_ASSUME_NONNULL_END
