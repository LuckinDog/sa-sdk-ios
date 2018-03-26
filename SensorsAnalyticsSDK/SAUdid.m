//
//  SAUdid.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/3/26.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import "SAUdid.h"
NSString * kSAUDIDSERVICE = @"com.sensorsdata.analytics.udid";
NSString * kSAUDIDACCOUNT = @"udid";
@implementation SAUdid
+(NSString *)saUdid
{
    NSString *sa_udid = nil;
    NSMutableDictionary *query = [[NSMutableDictionary alloc]init];
    CFTypeRef queryResults = NULL;
    CFErrorRef error = NULL;
    SecAccessControlRef secAccessControl =  SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleAfterFirstUnlock, kSecAccessControlUserPresence, &error);
    if (error) {
        return sa_udid;
    }else {
        [query setObject:(__bridge id)secAccessControl forKey:(__bridge id)kSecAttrAccessControl];
        CFRelease(secAccessControl);
    }
    
    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id) kSecClass];
    [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id) kSecMatchLimit ];
    
    [query setObject:kSAUDIDACCOUNT forKey:(__bridge id) kSecAttrAccount];
    [query setObject:kSAUDIDSERVICE forKey:(__bridge id) kSecAttrService];
    
    OSStatus status =   SecItemCopyMatching((__bridge CFDictionaryRef)query, &queryResults);
    if (status == errSecSuccess) {
        NSData   *resultData = (__bridge_transfer  NSData *)queryResults;
        sa_udid = [[NSString alloc]initWithData:resultData encoding:NSUTF8StringEncoding];
        NSLog(@"%@",sa_udid);
    }else if(status == errSecItemNotFound){
        CFTypeRef cfDict = NULL;
        sa_udid = [NSUUID UUID].UUIDString;
        [query setObject:[sa_udid dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id) kSecValueData];
        [query removeObjectForKey:(__bridge id)kSecMatchLimit ];
        OSStatus result = SecItemAdd((__bridge CFDictionaryRef)query, &cfDict);
        if (result != errSecSuccess) {
            sa_udid = nil;
        }
    }
    return sa_udid;
}
@end
