//
//  SADeviceOrientationManager.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/5/21.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
@interface SADeviceOrientationConfig:NSObject
@property (nonatomic,strong) NSString *deviceOrientation;
@property (nonatomic,assign) BOOL enableTrackScreenOrientation;//default is NO
@property (nonatomic,assign) NSTimeInterval deviceMotionUpdateInterval; //default is 0.1 second
@end

@interface SADeviceOrientationManager : NSObject
@property (nonatomic,assign) NSTimeInterval deviceMotionUpdateInterval;
@property (nonatomic,strong) void(^deviceOrientationBlock)(NSString * deviceOrientation);
- (void)startDeviceMotionUpdates;
- (void)stopDeviceMotionUpdates;
@end
