//
//  SAUdid.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/3/26.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>
extern const NSString *kSAUDIDSERVICE;
extern const NSString *kSAUDIDACCOUNT;

@interface SAUdid : NSObject
+(NSString *)saUdid;
+(NSString *)saveUdid:(NSString *)udid;
@end
