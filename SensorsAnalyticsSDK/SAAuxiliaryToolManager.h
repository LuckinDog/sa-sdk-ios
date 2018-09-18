//
//  SAAuxiliaryToolManager.h
//  SensorsAnalyticsSDK
//
//  Created by ziven.mac on 2018/9/7.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAVisualAutoTrackConnection.h"
#import "SAHeatMapConnection.h"
NS_ASSUME_NONNULL_BEGIN

@interface SAAuxiliaryToolManager : NSObject
+(instancetype)sharedInstance;

-(BOOL)canOpenURL:(NSURL *)URL;
-(BOOL)openURL:(NSURL *)URL  isWifi:(BOOL)isWifi;
@end

NS_ASSUME_NONNULL_END
