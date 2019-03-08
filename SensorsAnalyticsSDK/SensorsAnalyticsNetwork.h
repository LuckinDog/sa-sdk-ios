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

- (void)flushEvents:(NSArray<NSString *> *)events;

@end

NS_ASSUME_NONNULL_END
