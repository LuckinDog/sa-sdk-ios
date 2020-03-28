//
// SAIdentifier.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/2/17.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAIdentifier.h"
#import "SAConstants+Private.h"
#import "SAFileStore.h"
#import "SALogger.h"
#import "SAValidator.h"

#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
    #import "SAKeyChainItemWrapper.h"
#endif

@interface SAIdentifier ()

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, copy, readwrite) NSString *loginId;
@property (nonatomic, copy, readwrite) NSString *originalId;
@property (nonatomic, copy, readwrite) NSString *anonymousId;

@end

@implementation SAIdentifier

#pragma mark - Life Cycle

- (instancetype)initWithGlobalQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        self.queue = queue;
        self.anonymousId = [self unarchiveAnonymousId];
        self.loginId = [SAFileStore unarchiveWithFileName:SA_EVENT_LOGIN_ID];
    }
    return self;
}

#pragma mark - Public Methods

- (void)identify:(NSString *)anonymousId {
    if (![SAValidator isValidString:anonymousId]) {
        SAError(@"%@ anonymopausId:%@ is invalid parameter for identify", self, anonymousId);
        return;
    }

    if ([anonymousId length] > 255) {
        SAError(@"%@ anonymopausId:%@ is beyond the maximum length 255", self, anonymousId);
        return;
    }

    NSString *originalId = self.anonymousId;
    sensorsdata_dispatch_safe_sync(self.queue, ^{
        self.originalId = originalId;
        self.anonymousId = anonymousId;
    });
    [self archiveAnonymousId:anonymousId];
}

- (void)archiveAnonymousId:(NSString *)anonymousId {
    [SAFileStore archiveWithFileName:SA_EVENT_DISTINCT_ID value:anonymousId];
#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
        [SAKeyChainItemWrapper saveUdid:anonymousId];
#endif
}

- (void)resetAnonymousId {
    NSString *anonymousId = [SAIdentifier generateUniqueHardwareId];
    sensorsdata_dispatch_safe_sync(self.queue, ^{
        self.anonymousId = anonymousId;
    });
    [self archiveAnonymousId:anonymousId];
}

- (BOOL)login:(NSString *)loginId completion:(nullable dispatch_block_t)completion {
    if (![SAValidator isValidString:loginId]) {
        SAError(@"%@ loginId:%@ is invalid parameter for login", self, loginId);
        return NO;
    }

    if ([loginId length] > 255) {
        SAError(@"%@ loginId:%@ is beyond the maximum length 255", self, loginId);
        return NO;
    }

    if ([loginId isEqualToString:self.loginId]) {
        return NO;
    }

    NSString *originalId = self.anonymousId;
    sensorsdata_dispatch_safe_sync(self.queue, ^{
        self.loginId = loginId;
        if (![loginId isEqualToString:originalId]) {
            self.originalId = originalId;
            if (completion) {
                completion();
            }
        }
    });
    [SAFileStore archiveWithFileName:SA_EVENT_LOGIN_ID value:loginId];
    return YES;
}

- (void)logout {
    sensorsdata_dispatch_safe_sync(self.queue, ^{
        self.loginId = nil;
    });
    [SAFileStore archiveWithFileName:SA_EVENT_LOGIN_ID value:nil];
}

+ (NSString *)idfa {
    NSString *idfa = nil;
    // 宏 SENSORS_ANALYTICS_IDFA 定义时，优先使用IDFA
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID * (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        idfa = [uuid UUIDString];
        // 在 iOS 10.0 以后，当用户开启限制广告跟踪，advertisingIdentifier 的值将是全零
        // 00000000-0000-0000-0000-000000000000
        if ([idfa hasPrefix:@"00000000"]) {
            return nil;
        }
    }
    return idfa;
}

+ (NSString *)generateUniqueHardwareId {
    NSString *distinctId = [self idfa];

    // 没有IDFA，则使用IDFV
    if (!distinctId && NSClassFromString(@"UIDevice")) {
        distinctId = [UIDevice currentDevice].identifierForVendor.UUIDString;
    }

    // 没有IDFV，则使用UUID
    if (!distinctId) {
        SADebug(@"%@ error getting device identifier: falling back to uuid", self);
        distinctId = [NSUUID UUID].UUIDString;
    }
    return distinctId;
}

#pragma mark – Private Methods

- (NSString *)unarchiveAnonymousId {
    NSString *anonymousId = [SAFileStore unarchiveWithFileName:SA_EVENT_DISTINCT_ID];

#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
    NSString *distinctIdInKeychain = [SAKeyChainItemWrapper saUdid];
    if (distinctIdInKeychain.length > 0) {
        if (![anonymousId isEqualToString:distinctIdInKeychain]) {
            [self archiveAnonymousId:distinctIdInKeychain];
        }
        anonymousId = distinctIdInKeychain;
    } else {
#endif
        if (anonymousId.length == 0) {
            anonymousId = [SAIdentifier generateUniqueHardwareId];
            [self archiveAnonymousId:anonymousId];
        } else {
#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
            //保存 KeyChain
            [SAKeyChainItemWrapper saveUdid:anonymousId];
        }
#endif
    }
    return anonymousId;
}

#pragma mark – Getters and Setters
- (NSString *)anonymousId {
    if (!_anonymousId) {
        [self resetAnonymousId];
    }
    return _anonymousId;
}

- (NSString *)distinctId {
    __block NSString *distinctId = nil;
    dispatch_block_t block = ^{
        distinctId = self.loginId;
        if (distinctId.length == 0) {
            distinctId = self.anonymousId;
        }
    };
    sensorsdata_dispatch_safe_sync(self.queue, block);
    return distinctId;
}

@end
