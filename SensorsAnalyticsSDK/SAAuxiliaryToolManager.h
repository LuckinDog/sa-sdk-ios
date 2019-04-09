//
//  SAAuxiliaryToolManager.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/9/7.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAVisualAutoTrackConnection.h"
#import "SAHeatMapConnection.h"
NS_ASSUME_NONNULL_BEGIN

@interface SAAuxiliaryToolManager : NSObject
+ (instancetype)sharedInstance;

- (BOOL)canHandleURL:(NSURL *)url;
- (BOOL)handleURL:(NSURL *)url  isWifi:(BOOL)isWifi;


- (BOOL)isVisualHeatMapURL:(NSURL *)url;
- (BOOL)isVisualAutoTrackURL:(NSURL *)url;
- (BOOL)isVisualDebugModeURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
