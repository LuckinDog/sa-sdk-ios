//
//  SADesignerSnapshotMessage.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/9/4.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SAVisualizedAutoTrackAbstractMessage.h"

@class SAObjectSerializerConfig;

extern NSString *const SAVisualizedAutoTrackSnapshotRequestMessageType;

#pragma mark -- Snapshot Request

@interface SAVisualizedAutoTrackSnapshotRequestMessage : SAVisualizedAutoTrackAbstractMessage

+ (instancetype)message;

@property (nonatomic, readonly) SAObjectSerializerConfig *configuration;

@end

#pragma mark -- Snapshot Response

@interface SAVisualizedAutoTrackSnapshotResponseMessage : SAVisualizedAutoTrackAbstractMessage

+ (instancetype)message;

@property (nonatomic, strong) UIImage *screenshot;
@property (nonatomic, copy) NSDictionary *serializedObjects;
@property (nonatomic, strong) NSString *imageHash;

@end
