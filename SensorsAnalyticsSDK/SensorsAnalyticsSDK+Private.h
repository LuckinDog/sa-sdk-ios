//
//  SensorsAnalyticsSDK_priv.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/8/9.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#ifndef SensorsAnalyticsSDK_Private_h
#define SensorsAnalyticsSDK_Private_h
#import "SensorsAnalyticsSDK.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/Webkit.h>
@interface SensorsAnalyticsSDK(Private)
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item;
@end

#endif /* SensorsAnalyticsSDK_priv_h */
