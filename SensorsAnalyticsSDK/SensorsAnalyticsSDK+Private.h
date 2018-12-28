//
//  SensorsAnalyticsSDK_priv.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/8/9.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#ifndef SensorsAnalyticsSDK_Private_h
#define SensorsAnalyticsSDK_Private_h
#import "SensorsAnalyticsSDK.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/Webkit.h>

/**
 埋点方式

 - SensorsAnalyticsTrackTypeCode: 代码埋点
 - SensorsAnalyticsTrackTypeSA: 神策埋点
 */
typedef NS_ENUM(NSInteger, SensorsAnalyticsTrackType) {
    SensorsAnalyticsTrackTypeCode,
    SensorsAnalyticsTrackTypeSA,
};

@interface SensorsAnalyticsSDK(Private)
- (void)autoTrackViewScreen:(UIViewController *)viewController;

- (void)track:(NSString *)event withTrackType:(SensorsAnalyticsTrackType)trackType;

- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict withTrackType:(SensorsAnalyticsTrackType)trackType;
@end

#endif /* SensorsAnalyticsSDK_priv_h */
