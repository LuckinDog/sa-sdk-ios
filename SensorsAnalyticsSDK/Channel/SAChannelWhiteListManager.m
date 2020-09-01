//
// SAChannelWhiteListManager.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/8/29.
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

#import "SAChannelWhiteListManager.h"
#import "SAChannelWhiteListController.h"
#import "SAChannelMatchManager.h"

@implementation SAChannelWhiteListManager

+ (void)showAuthorizationAlert {

    SAChannelWhiteListTemplateModel *templateModel = [[SAChannelWhiteListTemplateModel alloc] init];
    templateModel.title = @"即将开启「渠道白名单」模式";

    SAChannelWhiteListTemplateActionModel *confirmActionModel = [[SAChannelWhiteListTemplateActionModel alloc] init];
    confirmActionModel.text = @"确定";
    confirmActionModel.textColor = [UIColor whiteColor];
    confirmActionModel.backgroundColor = [UIColor cyanColor];
    confirmActionModel.channelAction = ^{
        [self checkAppInstallationEventDetails];
    };

    SAChannelWhiteListTemplateActionModel *cancelActionModel = [[SAChannelWhiteListTemplateActionModel alloc] init];
    cancelActionModel.text = @"取消";
    cancelActionModel.textColor = [UIColor lightGrayColor];
    cancelActionModel.backgroundColor = [UIColor clearColor];

    templateModel.actions = @[confirmActionModel, cancelActionModel];
    SAChannelWhiteListController *controller = [[SAChannelWhiteListController alloc] initWithTemplateModel:templateModel];

    [controller show];
}

+ (void)checkAppInstallationEventDetails {
    SAChannelMatchManager *manager = [SAChannelMatchManager manager];
    if (![manager appInstalled] || ([manager appInstalled] && [manager deviceEmpty])) {
        [self showAppInstallAlert];
    } else {
        [self showErrorMessageAlert];
    }
}

+ (void)showAppInstallAlert {
    SAChannelWhiteListTemplateModel *templateModel = [[SAChannelWhiteListTemplateModel alloc] init];
    templateModel.title = @"成功开启「渠道白名单」模式";
    templateModel.content = @"此模式下不需要卸载 App，点击下列 “激活” 按钮可以反复触发激活";

    SAChannelWhiteListTemplateActionModel *confirmActionModel = [[SAChannelWhiteListTemplateActionModel alloc] init];
    confirmActionModel.text = @"激活";
    confirmActionModel.textColor = [UIColor whiteColor];
    confirmActionModel.backgroundColor = [UIColor systemBlueColor];
    templateModel.actions = @[confirmActionModel];
    SAChannelWhiteListController *controller = [[SAChannelWhiteListController alloc] initWithTemplateModel:templateModel];
    [controller show];
}

+ (void)showErrorMessageAlert {
    SAChannelWhiteListTemplateModel *templateModel = [[SAChannelWhiteListTemplateModel alloc] init];
    templateModel.title = @"检测到 “设备码为空”，可能原因如下：请排查：\n 1.手机系统设置中选择禁用设备码；\n 2. SDK 代码有误，请联系研发人员确认是否关闭“采集设备码”开关 \n 卸载并安装重新集成了修正的 SDK 的 app，再进行";
    templateModel.content = @"";
    SAChannelWhiteListController *controller = [[SAChannelWhiteListController alloc] initWithTemplateModel:templateModel];
    [controller show];
}

@end
