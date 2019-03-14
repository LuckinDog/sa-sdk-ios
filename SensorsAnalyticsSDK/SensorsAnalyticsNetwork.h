//
//  SensorsAnalyticsNetwork.h
//  SensorsAnalyticsSDK
//
//  Created by MC on 2019/3/8.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsNetwork : NSObject

@property (nonatomic, strong) NSData *certificateData;

- (instancetype)initWithServerURL:(NSURL *)serverURL;

/**
 * @abstract
 * 设置 Cookie
 *
 * @param cookie NSString cookie
 * @param encode BOOL 是否 encode
 */
- (void)setCookie:(NSString *)cookie withEncode:(BOOL)encode;

/**
 * @abstract
 * 返回已设置的 Cookie
 *
 * @param decode BOOL 是否 decode
 * @return NSString cookie
 */
- (NSString *)cookieWithDecode:(BOOL)decode;


/**
 将数据上传到 Sensors Analytics 的服务器上
 数据将同步发送，请在异步线程中调用

 @param events 事件的 json 字符串组成的数组
 @return 同步返回数据是否上传成功
 */
- (BOOL)flushEvents:(NSArray<NSString *> *)events;

@end

NS_ASSUME_NONNULL_END
