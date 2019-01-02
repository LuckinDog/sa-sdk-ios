//
//  SACommonUtility.m
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2018/7/26.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "SACommonUtility.h"

@implementation SACommonUtility


///按字节截取指定长度字符，包括汉字
+ (NSString *)subByteString:(NSString *)string byteLength:(NSInteger )len {
    
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF8);
    NSData* data = [string dataUsingEncoding:enc];
    
    NSData *data1 = [data subdataWithRange:NSMakeRange(0,len)];
    NSString*txt=[[NSString alloc]initWithData:data1 encoding:enc];
    
    //utf8 汉字占三个字节，可能截取失败
    if (!txt) {
        data1 = [data subdataWithRange:NSMakeRange(0, len-1)];
        txt=[[NSString alloc]initWithData:data1 encoding:enc];
    }
    if (!txt) {
        data1 = [data subdataWithRange:NSMakeRange(0, len-2)];
        txt=[[NSString alloc]initWithData:data1 encoding:enc];
    }
    if (!txt) {
        data1 = [data subdataWithRange:NSMakeRange(0, len-3)];
        txt=[[NSString alloc]initWithData:data1 encoding:enc];
    }
//    txt = [string getBytes:<#(nullable void *)#> maxLength:<#(NSUInteger)#> usedLength:<#(nullable NSUInteger *)#> encoding:<#(NSStringEncoding)#> options:<#(NSStringEncodingConversionOptions)#> range:<#(NSRange)#> remainingRange:<#(nullable NSRangePointer)#>]
    
    if (!txt) {
        return string;
    }
    return txt;
}
@end
