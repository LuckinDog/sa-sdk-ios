//
//  SensorsAnalyticsSDK_priv.h
//  SensorsAnalyticsSDK
//
//  Created by ziven.mac on 2018/8/9.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#ifndef SensorsAnalyticsSDK_priv_h
#define SensorsAnalyticsSDK_priv_h
#import "SensorsAnalyticsSDK.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/Webkit.h>
@interface SensorsAnalyticsSDK(priv)
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler  isSensorsReq:(BOOL *)isSensorsReq;
-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item;
@end

#endif /* SensorsAnalyticsSDK_priv_h */
