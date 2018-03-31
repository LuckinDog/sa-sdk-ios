//
//  SALogger.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/3/28.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SALogger.h"
static BOOL __enableLog__ ;
static dispatch_queue_t __logQueue__ ;
@implementation SALogger
+(void)initialize {
    __enableLog__ = NO;
    __logQueue__ = dispatch_queue_create("com.sensorsdata.analytics.log", DISPATCH_QUEUE_SERIAL);
}
+(void)enableLog:(BOOL)enableLog {
    dispatch_sync(__logQueue__, ^{
        __enableLog__ = enableLog;
    });
}

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
+ (void)log:(BOOL)asynchronous
      level:(NSInteger)level
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
     format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    [self.sharedInstance log:asynchronous message:message level:level file:file function:function line:line];
    va_end(args);
}
- (void)log:(BOOL)asynchronous
    message:(NSString *)message
      level:(NSInteger)level
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line {
    NSString *logMessage = [[NSString alloc]initWithFormat:@"[SALog][level %ld]  %s [line %lu]    %s %@",(long)level,function,(unsigned long)line,[@"" UTF8String],message];
    if (__enableLog__) {
        NSLog(@"%@",logMessage);
    }
    dispatch_block_t block = ^(){
        NSString *path = [NSHomeDirectory() stringByAppendingString:@"/Library/SALog.log"];
        if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
            [[NSFileManager defaultManager]createFileAtPath:path contents:[NSData data] attributes:nil];
        }
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
        [handle seekToEndOfFile];
        NSDate *currentDate = NSDate.date;
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss zzz";
        NSString *time = [formatter stringFromDate:currentDate];
        NSString *log = [[NSString alloc]initWithFormat:@"%@ %@\n",time ,logMessage];
        [handle writeData:[ log dataUsingEncoding:NSUTF8StringEncoding]];
    };
    dispatch_sync(__logQueue__, block);
}

-(void)dealloc {
    
}
@end

