//
//  AutoTrackUtils.h
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/6/29.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AutoTrackUtils : NSObject

+ (void)trackAppClickWithUITableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

+ (void)trackAppClickWithUICollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

+ (NSString *)contentFromView:(UIView *)rootView;

//+ (void)sa_addViewPathProperties:(NSMutableDictionary *)properties withObject:(UIView *)view withViewController:(UIViewController *)viewController;

+ (void)sa_addViewPathProperties:(NSMutableDictionary *)properties object:(UIView *)view viewController:(UIViewController *)viewController;

+ (void)trackAppClickWithUITabBar:(UITabBar *)tabbar didSelectItem:(UITabBarItem *)item;

+ (void)trackAppClickWithUIGestureRecognizer:(UIGestureRecognizer *)gesture;
+ (NSString *)titleFromViewController:(UIViewController *)viewController;

@end
