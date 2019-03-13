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

- (void)flushEvents:(NSArray<NSString *> *)events;
- (void)flushEvents:(NSArray<NSString *> *)events completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
