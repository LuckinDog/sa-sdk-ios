//
//  SAVisualAutoTrackMessage.h
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 8/1/17.
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
/// Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SAVisualAutoTrackConnection;

@protocol SAVisualAutoTrackMessage <NSObject>

@property (nonatomic, copy, readonly) NSString *type;

- (void)setPayloadObject:(id)object forKey:(NSString *)key;
- (id)payloadObjectForKey:(NSString *)key;

- (NSData *)JSONData:(BOOL)useGzip withFeatuerCode:(NSString *)fetureCode;

- (NSOperation *)responseCommandWithConnection:(SAVisualAutoTrackConnection *)connection;

@end
