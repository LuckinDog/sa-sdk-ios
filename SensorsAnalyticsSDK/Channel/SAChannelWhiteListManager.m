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
#import "SensorsAnalyticsSDK+Private.h"

#define RGB(r, g, b) [UIColor colorWithRed:(r) green:(g) blue:(b) alpha:1]

@implementation SAChannelWhiteListManager

+ (BOOL)canOpenURL:(NSURL *)url {
    return [url.host isEqualToString:@"channeldebug"];
}

+ (void)showAuthorizationAlert {

    SAChannelWhiteListTemplateModel *templateModel = [[SAChannelWhiteListTemplateModel alloc] init];
    NSString *text = @"即将开启「渠道白名单」模式";
    UIColor *color = RGB(0.28, 0.34, 0.41);
    UIFont *font = [UIFont boldSystemFontOfSize:16];
    templateModel.title = [self attributedString:text color:color font:font lineSpacing:0 textAlign:NSTextAlignmentCenter];

    SAChannelWhiteListTemplateActionModel *confirmActionModel = [[SAChannelWhiteListTemplateActionModel alloc] init];
    confirmActionModel.text = @"确定";
    confirmActionModel.textColor = [UIColor whiteColor];
    confirmActionModel.backgroundColor =  [UIColor colorWithRed:0 green:0.77 blue:0.56 alpha:1];
    confirmActionModel.channelAction = ^{
        [self isValidTrackInstallation];
    };
    SAChannelWhiteListTemplateActionModel *cancelActionModel = [[SAChannelWhiteListTemplateActionModel alloc] init];
    cancelActionModel.text = @"取消";
    cancelActionModel.textColor = [UIColor lightGrayColor];
    cancelActionModel.backgroundColor = [UIColor clearColor];
    cancelActionModel.channelAction = ^{

    };

    templateModel.actions = @[confirmActionModel, cancelActionModel];
    SAChannelWhiteListController *controller = [[SAChannelWhiteListController alloc] initWithTemplateModel:templateModel];

    [controller show];
}

+ (void)isValidTrackInstallation {
    SAChannelMatchManager *manager = [SAChannelMatchManager manager];
    if (![manager appInstalled] || ([manager appInstalled] && [manager deviceIdEmpty])) {
        [self saveUserInfoIntoWhitList];
    } else {
        [self showErrorMessageAlert];
    }
}

+ (void)saveUserInfoIntoWhitList {
    // 请求逻辑地址修改
    NSURL *serverURL = SensorsAnalyticsSDK.sharedInstance.network.serverURL;
    if (serverURL.absoluteString.length <= 0) {
        return;
    }
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = serverURL.scheme;
    components.host = serverURL.host;
    components.path = @"/sdk/channeldebug";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:components.URL];
    request.timeoutInterval = 60;
    [request setHTTPMethod:@"POST"];

    NSDictionary *dic = @{@"distinct_id":[[SensorsAnalyticsSDK sharedInstance] distinctId],@"flag":@([[SAChannelMatchManager manager] deviceIdEmpty])};
    NSData *HTTPBody= [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    request.HTTPBody = HTTPBody;

    if (!request) {
        return;
    }
    NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
        if (response.statusCode == 200) {
            [self showAppInstallAlert];
        }
    }];
    [task resume];
}

+ (void)showAppInstallAlert {
    SAChannelWhiteListTemplateModel *templateModel = [[SAChannelWhiteListTemplateModel alloc] init];
    NSString *title = @"成功开启「渠道白名单」模式";
    UIColor *titleColor = RGB(0.28, 0.34, 0.41);
    UIFont *titleFont = [UIFont boldSystemFontOfSize:16];
    templateModel.title = [self attributedString:title color:titleColor font:titleFont lineSpacing:0 textAlign:NSTextAlignmentCenter];

    NSString *content = @"此模式下不需要卸载 App，点击下列 “激活” 按钮可以反复触发激活";
    UIColor *contentColor = RGB(0.28, 0.34, 0.41);
    UIFont *contentFont = [UIFont systemFontOfSize:14];
    templateModel.content = [self attributedString:content color:contentColor font:contentFont lineSpacing:0 textAlign:NSTextAlignmentCenter];

    SAChannelWhiteListTemplateActionModel *confirmActionModel = [[SAChannelWhiteListTemplateActionModel alloc] init];
    confirmActionModel.text = @"激活";
    confirmActionModel.textColor = [UIColor whiteColor];
    confirmActionModel.backgroundColor = [UIColor systemBlueColor];
    confirmActionModel.channelAction = ^{
        [[SAChannelMatchManager manager] trackAppInstallEvent];
    };
    templateModel.actions = @[confirmActionModel];
    SAChannelWhiteListController *controller = [[SAChannelWhiteListController alloc] initWithTemplateModel:templateModel];
    [controller show];
}

+ (void)showErrorMessageAlert {
    SAChannelWhiteListTemplateModel *templateModel = [[SAChannelWhiteListTemplateModel alloc] init];
    NSMutableAttributedString * titleAttr = [[NSMutableAttributedString alloc] init];

    UIColor *defaultColor = RGB(0.28, 0.34, 0.41);
    UIFont *defaultFont = [UIFont boldSystemFontOfSize:16];
    NSAttributedString *part1 = [self attributedString:@"检测到" color:defaultColor font:defaultFont lineSpacing:0 textAlign:NSTextAlignmentCenter];
    [titleAttr appendAttributedString:part1];

    NSString *text = @"检测到 ，可能原因如下，请排查：";
    UIColor *color = [UIColor colorWithRed:0.28 green:0.34 blue:0.41 alpha:1];
    templateModel.title = [self attributedString:@"“设备码为空”" color:RGB(0.28, 0.34, 0.41) font:defaultFont lineSpacing:0 textAlign:NSTextAlignmentCenter];

    NSMutableAttributedString * attriStr = [[NSMutableAttributedString alloc] init];
    NSTextAttachment *num1 = [[NSTextAttachment alloc] init];
    num1.bounds = CGRectMake(0, 0, 16, 16);
    num1.image = [self errorMessageNumberImage:@"1"];
    NSAttributedString *image1 = [NSAttributedString attributedStringWithAttachment:num1];
    [attriStr appendAttributedString:image1];
    [attriStr appendAttributedString:[[NSAttributedString alloc] initWithString:@" 手机系统设置中选择禁用设备码；\n\n"]];

    NSTextAttachment *num2 = [[NSTextAttachment alloc] init];
    num2.bounds = CGRectMake(0, 0, 16, 16);
    num2.image = [self errorMessageNumberImage:@"2"];
    NSAttributedString *image2 = [NSAttributedString attributedStringWithAttachment:num2];
    [attriStr appendAttributedString:image2];
    [attriStr appendAttributedString:[[NSAttributedString alloc] initWithString:@" SDK 代码有误，请联系研发人员确认是否关闭“采集设备码”开关 \n\n"]];
    [attriStr appendAttributedString:[[NSAttributedString alloc] initWithString:@"卸载并安装重新集成了修正的 SDK 的 app，再进行"]];

    templateModel.content = attriStr;
//    templateModel.title = @"检测到 “设备码为空”，可能原因如下：请排查：\n ";
//    templateModel.content = @"1.手机系统设置中选择禁用设备码；\n 2. SDK 代码有误，请联系研发人员确认是否关闭“采集设备码”开关 \n 卸载并安装重新集成了修正的 SDK 的 app，再进行";
    SAChannelWhiteListController *controller = [[SAChannelWhiteListController alloc] initWithTemplateModel:templateModel];
    [controller show];
}

#pragma mark - Utils
+ (UIImage *)errorMessageNumberImage:(NSString *)imageSubfix {
    NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[SensorsAnalyticsSDK class]] pathForResource:@"SensorsAnalyticsSDK" ofType:@"bundle"]];
    //文件路径
    NSString *imagePath = [sensorsBundle pathForResource:[NSString stringWithFormat:@"number_%@", imageSubfix] ofType:@"png"];
    NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
    UIImage *image = [UIImage imageWithData:imageData];
    return image;
}

+ (NSAttributedString *)attributedString:(NSString *)text color:(UIColor *)color font:(UIFont *)font lineSpacing:(CGFloat)lineSpacing textAlign:(NSTextAlignment)textAlign {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:4];
    attributes[NSFontAttributeName] = font;
    attributes[NSForegroundColorAttributeName] = color;
    attributes[NSKernAttributeName] = @(1);
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.lineSpacing = lineSpacing;
    style.alignment = textAlign;
    attributes[NSParagraphStyleAttributeName] = style;
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributes];
    return attributedText;
}

@end
