//
//  SADesignerSnapshotMessage.h
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 8/1/17.
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
/// Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SAVisualAutoTrackAbstractMessage.h"

@class SAObjectSerializerConfig;

extern NSString *const SAVisualAutoTrackSnapshotRequestMessageType;

#pragma mark -- Snapshot Request

@interface SAVisualAutoTrackSnapshotRequestMessage : SAVisualAutoTrackAbstractMessage

+ (instancetype)message;

@property (nonatomic, readonly) SAObjectSerializerConfig *configuration;

@end

#pragma mark -- Snapshot Response

@interface SAVisualAutoTrackSnapshotResponseMessage : SAVisualAutoTrackAbstractMessage

+ (instancetype)message;

@property (nonatomic, strong) UIImage *screenshot;
@property (nonatomic, copy) NSDictionary *serializedObjects;
@property (nonatomic, strong) NSString *imageHash;

@end
