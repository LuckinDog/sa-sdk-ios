//
//  SaAlertRootViewController.h
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2019/3/4.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 神策弹框的 RootViewController，添加到黑名单。
 * 防止 $AppViewScreen 事件误采
 */
@interface SaAlertRootViewController : UIViewController


/**
 神策 AlterViewControllee 初始化

 @param title 标题
 @param message 提示信息
 @param preferredStyle 弹框类型
 @return controller
 */
- (instancetype)initWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle;

- (void)addActionWithTitle:(NSString *_Nullable)title style:(UIAlertActionStyle)style handler:(void (^ __nullable)(void))handler;

- (void)showAlertViewController;

@end

NS_ASSUME_NONNULL_END
