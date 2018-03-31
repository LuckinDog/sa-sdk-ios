//
//  SALogger.h
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/6.
//  Copyright (c) 2015年 SensorsData. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifndef __SensorsAnalyticsSDK__SALogger__
#define __SensorsAnalyticsSDK__SALogger__

#define SALog(fmt,...) \
[SALogger log : YES                                      \
level : 1                                                   \
file : __FILE__                                            \
function : __PRETTY_FUNCTION__                       \
line : __LINE__                                           \
format : (fmt), ## __VA_ARGS__]

#define SAError SALog
#define SADebug SALog

#endif

@interface SALogger:NSObject
@property(class , readonly, strong) SALogger *sharedInstance;
+ (void)enableLog:(BOOL)enableLog;
+ (void)log:(BOOL)asynchronous
      level:(NSInteger)level
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
     format:(NSString *)format, ... ;
@end


