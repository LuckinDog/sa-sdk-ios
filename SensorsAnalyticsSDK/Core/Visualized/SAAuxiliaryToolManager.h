//
//  SAAuxiliaryToolManager.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/9/7.
//  Copyright © 2015－2018 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAVisualizedConnection.h"


typedef NS_ENUM(NSInteger, SensorsAnalyticsVisualizedType) {
    SensorsAnalyticsVisualizedTypeUnkhow,  // 未知或不允许
    SensorsAnalyticsVisualizedTypeHeatMap, // 点击图
    SensorsAnalyticsVisualizedTypeAutoTrack  //可视化全埋点
};

NS_ASSUME_NONNULL_BEGIN

@interface SAAuxiliaryToolManager : NSObject
+ (instancetype)sharedInstance;

- (BOOL)canHandleURL:(NSURL *)url;
- (BOOL)handleURL:(NSURL *)url  isWifi:(BOOL)isWifi;

- (BOOL)isHeatMapURL:(NSURL *)url;
- (BOOL)isVisualizedAutoTrackURL:(NSURL *)url;
- (BOOL)isSecretKeyURL:(NSURL *)url;

- (BOOL)isVisualizedConnecting;

/// 当前类型
- (SensorsAnalyticsVisualizedType)currentVisualizedType;
@end

NS_ASSUME_NONNULL_END
