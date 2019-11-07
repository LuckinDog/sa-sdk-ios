//
//  JSCallWKWebViewController.m
//  SensorsData
//
//  Created by 储强盛 on 2019/10/29.
//  Copyright © 2019 SensorsData. All rights reserved.
//

#import "JSCallWKWebViewController.h"
#import <SensorsAnalyticsSDK/SensorsAnalyticsSDK.h>
#import <WebKit/WebKit.h>

@interface JSCallWKWebViewController ()
@property(nonatomic,strong) WKWebView *webView;
@end

@implementation JSCallWKWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    _webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    self.title = @"WKWebView";

    [[SensorsAnalyticsSDK sharedInstance] addScriptMessageHandlerWithWebView:self.webView];

//    NSString *path = [[[NSBundle mainBundle] bundlePath]  stringByAppendingPathComponent:@"index.html"];
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]];

    //网址
    NSString *httpStr = @"http://192.168.50.112/wkwebview/index.html";
    NSURL *httpUrl = [NSURL URLWithString:httpStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:httpUrl];

    [self.webView loadRequest:request];

    [self.view addSubview:_webView];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
