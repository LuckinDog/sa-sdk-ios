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

- (void)flushEvents:(NSArray<NSString *> *)events;
- (void)flushEvents:(NSArray<NSString *> *)events completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
