//
//  UIScrollView+AutoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by MC on 2019/4/30.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
    

#import "UIScrollView+AutoTrack.h"
#import "UIView+AutoTrack.h"

@implementation UITableViewCell (AutoTrack)

- (UIScrollView *)sensorsdata_scrollView {
    UITableView *tableView = nil;
    do {
        tableView = (UITableView *)self.superview;
    } while (![tableView isKindOfClass:UITableView.class]);
    return tableView;
}

- (NSString *)sensorsdata_elementId {
    return self.sensorsdata_scrollView.sensorsdata_elementId;
}

- (NSString *)sensorsdata_elementType {
    return NSStringFromClass(self.sensorsdata_scrollView.class);
}

- (NSString *)sensorsdata_elementPositionWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.row];
}

- (NSString *)sensorsdata_itemPathWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%@[%ld][%ld]", NSStringFromClass(self.class), (long)indexPath.section, (long)indexPath.row];
}

@end

@implementation UICollectionViewCell (AutoTrack)

- (UIScrollView *)sensorsdata_scrollView {
    UICollectionView *collectionView = nil;
    do {
        collectionView = (UICollectionView *)self.superview;
    } while (![collectionView isKindOfClass:UICollectionView.class]);
    return collectionView;
}

- (NSString *)sensorsdata_elementId {
    return self.sensorsdata_scrollView.sensorsdata_elementId;
}

- (NSString *)sensorsdata_elementType {
    return NSStringFromClass(self.sensorsdata_scrollView.class);
}

- (NSString *)sensorsdata_elementPositionWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.row];
}

- (NSString *)sensorsdata_itemPathWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat:@"%@[%ld][%ld]", NSStringFromClass(self.class), (long)indexPath.section, (long)indexPath.row];
}

@end
