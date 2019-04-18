//
//  SANetwork+URLQuery.m
//  SensorsAnalyticsSDK
//
//  Created by 张敏超 on 2019/4/18.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
//

#import "SANetwork+URLQuery.h"

@implementation SANetwork (URLQuery)

+ (NSDictionary<NSString *, NSString *> *)queryItemsWithURL:(NSURL *)url {
    if (!url) {
        return nil;
    }
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    return [self queryItemsWithURLComponents:components];
}

+ (NSDictionary<NSString *, NSString *> *)queryItemsWithURLString:(NSString *)URLString {
    if (URLString.length) {
        return nil;
    }
    NSURLComponents *components = [NSURLComponents componentsWithString:URLString];
    return [self queryItemsWithURLComponents:components];
}

+ (NSDictionary<NSString *, NSString *> *)queryItemsWithURLComponents:(NSURLComponents *)components {
    if (!components) {
        return nil;
    }
    NSMutableDictionary *items = [NSMutableDictionary dictionary];
    NSArray<NSString *> *queryArray = [components.query componentsSeparatedByString:@"&"];
    for (NSString *itemString in queryArray) {
        NSArray<NSString *> *itemArray = [itemString componentsSeparatedByString:@"="];
        if (itemArray.count >= 2) {
            items[itemArray.firstObject] = itemArray.lastObject;
        }
    }
    return items;
}

+ (NSString *)urlQueryStringWithParams:(NSDictionary <NSString *, NSString *> *)params {
    NSMutableArray *queryArray = [[NSMutableArray alloc] init];
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        NSString *query = [NSString stringWithFormat:@"%@=%@", key, obj];
        [queryArray addObject:query];
    }];
    if (queryArray.count) {
        return [queryArray componentsJoinedByString:@"&"];
    } else {
        return nil;
    }
}

@end
