//
//  SAVisualAutoTrackMessage.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/9/4.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SAVisualAutoTrackConnection;

@protocol SAVisualAutoTrackMessage <NSObject>

@property (nonatomic, copy, readonly) NSString *type;

- (void)setPayloadObject:(id)object forKey:(NSString *)key;
- (id)payloadObjectForKey:(NSString *)key;

- (NSData *)JSONData:(BOOL)useGzip featuerCode:(NSString *)fetureCode;

- (NSOperation *)responseCommandWithConnection:(SAVisualAutoTrackConnection *)connection;

@end
