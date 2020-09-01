//
// UIViewController.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/9/1.
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

#import "SAChannelWhiteListController.h"
#import "SensorsAnalyticsSDK.h"
#import <objc/runtime.h>

@implementation SAChannelWhiteListTemplateActionModel

@end

@implementation SAChannelWhiteListTemplateModel

@end

@interface UIButton (SAChannelWhiteList)

@property (nonatomic, copy) ChannelAction sensorsdata_channelAction;

@end

@implementation UIButton (SAChannelWhiteList)

- (void)setSensorsdata_channelAction:(ChannelAction)sensorsdata_channelAction {
    objc_setAssociatedObject(self, @"sensorsdata_channelAction", sensorsdata_channelAction, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (ChannelAction)sensorsdata_channelAction {
    return objc_getAssociatedObject(self, @"sensorsdata_channelAction");
}

@end

@interface SAChannelWhiteListController ()

@property (nonatomic, weak) UIWindow *appWindow;
@property (nonatomic, strong) UIWindow *popupWindow;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) SAChannelWhiteListTemplateModel *templateModel;

@end

#define kScreenWidth ([[UIScreen mainScreen] bounds].size.width)
#define kScreenHeight ([[UIScreen mainScreen] bounds].size.height)

@implementation SAChannelWhiteListController

- (instancetype)initWithTemplateModel:(SAChannelWhiteListTemplateModel *)templateModel {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
#ifdef __IPHONE_13_0
        if (@available(iOS 13.0, *)) {
            UIWindowScene *activeWindowScene = nil;
            for (UIWindowScene *windowScene in UIApplication.sharedApplication.connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    activeWindowScene = windowScene;
                    break;
                }
            }
            if (!activeWindowScene) {
                activeWindowScene = (UIWindowScene *)UIApplication.sharedApplication.connectedScenes.anyObject;
            }
            if (activeWindowScene) {
                _popupWindow = [[UIWindow alloc] initWithWindowScene:activeWindowScene];
            }
        }
#endif
        if (!_popupWindow) {
            _popupWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }
        _popupWindow.windowLevel = UIWindowLevelStatusBar + 1.0f;
        _popupWindow.backgroundColor = [UIColor clearColor];
        _templateModel = templateModel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    _contentView.backgroundColor = [UIColor whiteColor];
    _contentView.layer.cornerRadius = 5.0;
    self.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    [self.view addSubview:_contentView];
    [self displayWithTempleteModel:_templateModel];
}

- (void)viewDidLayoutSubviews {
    self.contentView.center = self.view.center;
    CGRect frame = self.contentView.frame;
//    frame.origin.y -= (20 + self.topOffset);
    self.contentView.frame = frame;
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
//    self.topOffset = (self.view.safeAreaInsets.top - 20);
}

- (void)show {
    self.appWindow = [UIApplication sharedApplication].keyWindow;
    if (self.appWindow.windowLevel != UIWindowLevelNormal) {
        self.appWindow = [UIApplication sharedApplication].windows.firstObject;
    }

    self.popupWindow.rootViewController = self;
    [self.popupWindow makeKeyAndVisible];
    self.popupWindow.hidden = NO;

    self.contentView.transform = CGAffineTransformScale(self.contentView.transform, 0.01, 0.01);
    [UIView animateWithDuration:0.3 animations:^{
        self.contentView.alpha = 1.0;
        self.contentView.transform = CGAffineTransformIdentity;
    }];
}

- (void)dismiss {
    [UIView animateWithDuration:0.3 animations:^{
        self.contentView.transform = CGAffineTransformScale(self.contentView.transform, 0.01, 0.01);
    } completion:^(BOOL finished) {
        [self dismissPopupWindow];
    }];
}

- (void)dismissPopupWindow {
    [self.popupWindow resignKeyWindow];
    self.popupWindow.hidden = YES;
    if (self.appWindow == nil || ![self.appWindow isKindOfClass:[UIWindow class]]) {
        self.appWindow = [UIApplication sharedApplication].windows.firstObject;
    }
    [self.appWindow makeKeyAndVisible];
    self.popupWindow = nil;
}

- (NSAttributedString *)attributedString:(NSString *)text color:(UIColor *)color font:(CGFloat)font alignment:(NSTextAlignment)textAlign {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:4];
    attributes[NSFontAttributeName] = [UIFont systemFontOfSize:font];
    attributes[NSForegroundColorAttributeName] = color;
    attributes[NSKernAttributeName] = @(1);
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.lineSpacing = font * 1.2 - font;
    style.alignment = textAlign;
    attributes[NSParagraphStyleAttributeName] = style;
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributes];
    return attributedText;
}

- (void)displayWithTempleteModel:(SAChannelWhiteListTemplateModel *)model {

    CGFloat elementX = 20.0;
    CGFloat nextElementY = 20.0;
    CGFloat verticalMargin = 20.0;
    CGFloat itemWidth = kScreenWidth - 40 * 2 - elementX * 2;

    UILabel *titleLabel = [[UILabel alloc] init];
    [_contentView addSubview:titleLabel];
    titleLabel.attributedText = [self attributedString:model.title color:[UIColor blackColor] font:20 alignment:NSTextAlignmentCenter];
    titleLabel.numberOfLines = 0;
    CGSize titleSize = [titleLabel sizeThatFits:CGSizeMake(itemWidth, MAXFLOAT)];
    titleLabel.frame = CGRectMake(elementX, nextElementY, itemWidth, titleSize.height);

    nextElementY = nextElementY + titleSize.height + verticalMargin;

    if (model.content.length) {
        UILabel *contentLabel = [[UILabel alloc] init];
        [_contentView addSubview:contentLabel];
        contentLabel.attributedText = [self attributedString:model.content color:[UIColor lightGrayColor] font:15 alignment:NSTextAlignmentLeft];
        contentLabel.numberOfLines = 0;
        CGSize contentSize = [contentLabel sizeThatFits:CGSizeMake(itemWidth, MAXFLOAT)];

        contentLabel.frame = CGRectMake(elementX, nextElementY, itemWidth, contentSize.height);
        nextElementY = nextElementY + contentSize.height + verticalMargin;
    }

    NSInteger index = 0;
    CGFloat buttonHeight = 45;
    for (SAChannelWhiteListTemplateActionModel *action in model.actions) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.sensorsAnalyticsIgnoreView = YES;
        button.backgroundColor = action.backgroundColor;
        [button setTitle:action.text forState:UIControlStateNormal];
        [button setTitleColor:action.textColor forState:UIControlStateNormal];
        [button addTarget:self action:@selector(elementClick:) forControlEvents:UIControlEventTouchUpInside];
        button.sensorsdata_channelAction = action.channelAction;
        button.layer.cornerRadius = 3.0;
        [_contentView addSubview:button];
        nextElementY = nextElementY + index * buttonHeight;
        button.frame = CGRectMake(elementX, nextElementY, itemWidth, buttonHeight);
        index++;
    }

    CGRect frame = _contentView.frame;
    CGFloat height = nextElementY + buttonHeight + verticalMargin;
    frame.size =  CGSizeMake(kScreenWidth - 40 * 2, height);
    _contentView.frame = frame;
}

- (void)elementClick:(UIButton *)button {
    ChannelAction channelAction = button.sensorsdata_channelAction;
    if (channelAction) {
        [self dismiss];
        channelAction();
    }
}

@end
