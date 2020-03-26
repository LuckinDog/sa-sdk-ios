//
// SAIdentifierManager.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/3/25.
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

#import "SAIdentifierManager.h"
#import "SAFileStore.h"
#import "SAConstants+Private.h"
#import "SAKeyChainItemWrapper.h"
#import <UIKit/UIKit.h>
#import "SALogger.h"

@interface SAIdentifierManager ()

@property (nonatomic, copy) NSString *distinctId;
@property (nonatomic, copy) NSString *loginId;
@property (nonatomic, copy) NSString *anonymousId;
@property (nonatomic, copy) NSString *originalId;

@end

@implementation SAIdentifierManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [self unarchiveIdentifiers];
    }
    return self;
}

-(NSString *)distinctId {
    NSString *distinctId = self.loginId;
    if (distinctId.length == 0) {
        distinctId = self.anonymousId;
    }
    return distinctId;
}

- (NSString *)anonymousId {
    if (!_anonymousId) {
        [self resetAnonymousId];
    }
    return _anonymousId;
}

- (void)unarchiveIdentifiers {
    [self unarchiveLoginId];
    [self unarchiveAnonymousId];
}

- (void)resetOriginalId {
    _originalId = _anonymousId;
}

#pragma mark - loginId
- (void)archiveLoginId:(nullable NSString *)loginId {
    self.loginId = loginId;
    [SAFileStore archiveWithFileName:SA_EVENT_LOGIN_ID value:self.loginId];
}

- (void)unarchiveLoginId {
    self.loginId = [SAFileStore unarchiveWithFileName:SA_EVENT_LOGIN_ID];
}

#pragma mark - anonymousId
- (void)resetAnonymousId {
    self.anonymousId = [self uniqueHardwareId];
    [self archiveAnonymousId];
}

- (void)unarchiveAnonymousId {
    NSString *archivedAnonymousId = (NSString *)[SAFileStore unarchiveWithFileName:SA_EVENT_DISTINCT_ID];

#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
    NSString *anonymousIdInKeychain = [SAKeyChainItemWrapper saUdid];
    if (anonymousIdInKeychain.length > 0) {
        self.anonymousId = anonymousIdInKeychain;
        if (![archivedAnonymousId isEqualToString:anonymousIdInKeychain]) {
            //保存 Archiver
            [SAFileStore archiveWithFileName:SA_EVENT_DISTINCT_ID value:self.anonymousId];
        }
    } else {
#endif
        if (archivedAnonymousId.length == 0) {
            self.anonymousId = [self uniqueHardwareId];
            [self archiveAnonymousId];
        } else {
            self.anonymousId = archivedAnonymousId;
#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
            //保存 KeyChain
            [SAKeyChainItemWrapper saveUdid:self.anonymousId];
        }
#endif
    }
}

- (void)archiveAnonymousId:(NSString *)anonymousId {
    self.anonymousId = anonymousId;
    [self archiveAnonymousId];
}

- (void)archiveAnonymousId {
    [SAFileStore archiveWithFileName:SA_EVENT_DISTINCT_ID value:self.anonymousId];
#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
    [SAKeyChainItemWrapper saveUdid:self.anonymousId];
#endif
}

- (NSString *)uniqueHardwareId {
    NSString *hardwareId = nil;

    //动态获取 IDFA
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID * (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        hardwareId = [uuid UUIDString];
        // 在 iOS 10.0 以后，当用户开启限制广告跟踪，advertisingIdentifier 的值将是全零
        // 00000000-0000-0000-0000-000000000000
        if (!hardwareId || [hardwareId hasPrefix:@"00000000"]) {
            hardwareId = nil;
        }
    }

    // 没有IDFA，则使用IDFV
    if (!hardwareId && NSClassFromString(@"UIDevice")) {
        hardwareId = [[UIDevice currentDevice].identifierForVendor UUIDString];
    }

    // 没有IDFV，则使用UUID
    if (!hardwareId) {
        SADebug(@"%@ error getting device identifier: falling back to uuid", self);
        hardwareId = [[NSUUID UUID] UUIDString];
    }
    return hardwareId;
}

@end
