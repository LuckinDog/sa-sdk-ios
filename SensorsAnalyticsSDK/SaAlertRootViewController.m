//
//  SaAlertRootViewController.m
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2019/3/4.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
//

#import "SaAlertRootViewController.h"

@interface SaAlertRootViewController ()
@property(nonatomic,strong) UIAlertController *alertController;
@property(nonatomic,weak) UIWindow *alertWindow;
@end

@implementation SaAlertRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (instancetype)initWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle {
    self = [super init];
    if (self) {
        _alertController = [UIAlertController
                                           alertControllerWithTitle:title
                                           message:message
                                           preferredStyle:preferredStyle];
        
        UIWindow *alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        alertWindow.rootViewController = self;
        alertWindow.windowLevel = UIWindowLevelAlert + 1;
        alertWindow.hidden = NO;
        _alertWindow = alertWindow;
    }
    return self;
}

- (void)addActionWithTitle:(NSString *)title style:(UIAlertActionStyle)style handler:(void (^ __nullable)(void))handler {
    
    __weak typeof(self) weakself = self;
    UIAlertAction *action = [UIAlertAction actionWithTitle:title style:style handler:^(UIAlertAction * _Nonnull action) {
        handler();
        weakself.alertWindow.hidden = YES;
        weakself.alertWindow = nil;
    }];
    
    [self.alertController addAction:action];
}

- (void)showAlertViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:self.alertController animated:YES completion:nil];
    });
}
@end
