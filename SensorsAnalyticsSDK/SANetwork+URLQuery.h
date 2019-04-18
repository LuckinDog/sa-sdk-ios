//
//  SANetwork+URLQuery.h
//  SensorsAnalyticsSDK
//
//  Created by 张敏超 on 2019/4/18.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
//

#import "SANetwork.h"

@interface SANetwork (URLQuery)

+ (NSDictionary<NSString *, NSString *> *)queryItemsWithURL:(NSURL *)url;
+ (NSDictionary<NSString *, NSString *> *)queryItemsWithURLString:(NSString *)URLString;

+ (NSString *)urlQueryStringWithParams:(NSDictionary <NSString *, NSString *> *)params;

@end
