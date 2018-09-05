//
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
/// Copyright (c) 2014 Mixpanel. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIView (SAHelpers)

- (UIImage *)sa_snapshotImage;
- (UIImage *)sa_snapshotForBlur;
- (int)mp_fingerprintVersion;

- (NSString *)jjf_varA;
- (NSString *)jjf_varB;
- (NSString *)jjf_varC;
- (NSArray *)jjf_varSetD;
- (NSString *)jjf_varE;

@end

@interface UITableViewCell (SAHelpers)
-(NSString*)sa_indexPath;
@end

@interface UICollectionViewCell (SAHelpers)
-(NSString*)sa_indexPath;
@end
