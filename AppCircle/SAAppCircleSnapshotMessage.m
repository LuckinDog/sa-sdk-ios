//
//  SADesignerSnapshotMessage.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 8/1/17.
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
/// Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

#import "SAAppCircleSnapshotMessage.h"
#import "SAApplicationStateSerializer.h"
#import "SAObjectIdentityProvider.h"
#import "SAObjectSerializerConfig.h"
#import "SAAppCircleConnection.h"
#import "SensorsAnalyticsSDK.h"

#pragma mark -- Snapshot Request

NSString * const SAAppCircleSnapshotRequestMessageType = @"snapshot_request";

static NSString * const kSnapshotSerializerConfigKey = @"snapshot_class_descriptions";
static NSString * const kObjectIdentityProviderKey = @"object_identity_provider";

@implementation SAAppCircleSnapshotRequestMessage

+ (instancetype)message {
    return [(SAAppCircleSnapshotRequestMessage *)[self alloc] initWithType:SAAppCircleSnapshotRequestMessageType];
}

- (SAObjectSerializerConfig *)configuration {
    NSDictionary *config = [self payloadObjectForKey:@"config"];
    return config ? [[SAObjectSerializerConfig alloc] initWithDictionary:config] : nil;
}

- (NSOperation *)responseCommandWithConnection:(SAAppCircleConnection *)connection {
    __block SAObjectSerializerConfig *serializerConfig = self.configuration;
    __block NSString *imageHash = [self payloadObjectForKey:@"last_image_hash"];

    __weak SAAppCircleConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        __strong SAAppCircleConnection *conn = weak_connection;
        
        // Update the class descriptions in the connection session if provided as part of the message.
        if (serializerConfig) {
            [connection setSessionObject:serializerConfig forKey:kSnapshotSerializerConfigKey];
        } else if ([connection sessionObjectForKey:kSnapshotSerializerConfigKey]){
            // Get the class descriptions from the connection session store.
            serializerConfig = [connection sessionObjectForKey:kSnapshotSerializerConfigKey];
        } else {
            // If neither place has a config, this is probably a stale message and we can't create a snapshot.
            return;
        }

        // Get the object identity provider from the connection's session store or create one if there is none already.
        SAObjectIdentityProvider *objectIdentityProvider = [[SAObjectIdentityProvider alloc] init];

        SAApplicationStateSerializer *serializer = [[SAApplicationStateSerializer alloc] initWithApplication:[UIApplication sharedApplication]
                                                                                               configuration:serializerConfig
                                                                                      objectIdentityProvider:objectIdentityProvider];

        SAAppCircleSnapshotResponseMessage *snapshotMessage = [SAAppCircleSnapshotResponseMessage message];
        __block UIImage *screenshot = nil;
        __block NSDictionary *serializedObjects = nil;

        dispatch_sync(dispatch_get_main_queue(), ^{
            
            screenshot = [serializer screenshotImageForWindow:UIApplication.sharedApplication.keyWindow];
        });
        snapshotMessage.screenshot = screenshot;

        if (imageHash && [imageHash isEqualToString:snapshotMessage.imageHash]) {
            [conn sendMessage:[SAAppCircleSnapshotResponseMessage message]];
            return;
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            serializedObjects = [serializer objectHierarchyForWindow:UIApplication.sharedApplication.keyWindow];
        });
        [connection setSessionObject:serializedObjects forKey:@"snapshot_hierarchy"];
        snapshotMessage.serializedObjects = serializedObjects;

        [conn sendMessage:snapshotMessage];
    }];

    return operation;
}

@end

#pragma mark -- Snapshot Response

@implementation SAAppCircleSnapshotResponseMessage

+ (instancetype)message {
    return [(SAAppCircleSnapshotResponseMessage *)[self alloc] initWithType:@"snapshot_response"];
}

- (void)setScreenshot:(UIImage *)screenshot {
    id payloadObject = nil;
    id imageHash = nil;
    if (screenshot) {
        NSData *jpegSnapshotImageData = UIImageJPEGRepresentation(screenshot, 0.5);
        if (jpegSnapshotImageData) {
            payloadObject = [jpegSnapshotImageData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
            imageHash = [self getImageHash:jpegSnapshotImageData];
        }
    }
    
    _imageHash = imageHash;
    [self setPayloadObject:(payloadObject ?: [NSNull null]) forKey:@"screenshot"];
    [self setPayloadObject:(imageHash ?: [NSNull null]) forKey:@"image_hash"];
}

- (UIImage *)screenshot {
    NSString *base64Image = [self payloadObjectForKey:@"screenshot"];
    NSData *imageData =[[base64Image dataUsingEncoding:NSUTF8StringEncoding] base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    return imageData ? [UIImage imageWithData:imageData] : nil;
}

- (void)setSerializedObjects:(NSDictionary *)serializedObjects {
    [self setPayloadObject:serializedObjects forKey:@"serialized_objects"];
}

- (NSDictionary *)serializedObjects {
    return [self payloadObjectForKey:@"serialized_objects"];
}

- (NSString *)getImageHash:(NSData *)imageData {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(imageData.bytes, (uint)imageData.length, result);
    NSString *imageHash = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                           result[0], result[1], result[2], result[3],
                           result[4], result[5], result[6], result[7],
                           result[8], result[9], result[10], result[11],
                           result[12], result[13], result[14], result[15]];
    return imageHash;
}

@end



