//
//  SAVisualAutoTrackAbstractMessage.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/9/4.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SAVisualAutoTrackMessage.h"

@interface SAVisualAutoTrackAbstractMessage : NSObject <SAVisualAutoTrackMessage>

@property (nonatomic, copy, readonly) NSString *type;

+ (instancetype)messageWithType:(NSString *)type payload:(NSDictionary *)payload;

- (instancetype)initWithType:(NSString *)type;
- (instancetype)initWithType:(NSString *)type payload:(NSDictionary *)payload;

- (void)setPayloadObject:(id)object forKey:(NSString *)key;
- (id)payloadObjectForKey:(NSString *)key;
- (NSDictionary *)payload;

- (NSData *)JSONData:(BOOL)useGzip featuerCode:(NSString *)fetureCode;

@end
