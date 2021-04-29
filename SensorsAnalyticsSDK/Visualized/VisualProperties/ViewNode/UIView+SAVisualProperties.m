//
// UIView+SAVisualProperties.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/6.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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

#import "UIView+SAVisualProperties.h"
#import "SAVisualizedManager.h"
#import <objc/runtime.h>

static void *const kSAViewNodePropertyName = (void *)&kSAViewNodePropertyName;

@implementation UIView (SAVisualProperties)

- (void)sensorsdata_visualize_didMoveToSuperview {
    [self sensorsdata_visualize_didMoveToSuperview];

    [SAVisualizedManager.sharedInstance.visualPropertiesTracker didMoveToSuperviewWithView:self];
}

- (void)sensorsdata_visualize_didMoveToWindow {
    [self sensorsdata_visualize_didMoveToWindow];

    [SAVisualizedManager.sharedInstance.visualPropertiesTracker didMoveToWindowWithView:self];
}

- (void)sensorsdata_visualize_didAddSubview:(UIView *)subview {
    [self sensorsdata_visualize_didAddSubview:subview];

    [SAVisualizedManager.sharedInstance.visualPropertiesTracker didAddSubview:subview];
}

- (void)sensorsdata_visualize_bringSubviewToFront:(UIView *)view {
    [self sensorsdata_visualize_bringSubviewToFront:view];
    if (view.sensorsdata_viewNode) {
        // 移动节点
        [self.sensorsdata_viewNode.subNodes removeObject:view.sensorsdata_viewNode];
        [self.sensorsdata_viewNode.subNodes addObject:view.sensorsdata_viewNode];
        
        // 兄弟节点刷新 Index
        [view.sensorsdata_viewNode refreshBrotherNodeIndex];
    }
}

- (void)sensorsdata_visualize_sendSubviewToBack:(UIView *)view {
    [self sensorsdata_visualize_sendSubviewToBack:view];
    if (view.sensorsdata_viewNode) {
        // 移动节点
        [self.sensorsdata_viewNode.subNodes removeObject:view.sensorsdata_viewNode];
        [self.sensorsdata_viewNode.subNodes insertObject:view.sensorsdata_viewNode atIndex:0];
        
        // 兄弟节点刷新 Index
        [view.sensorsdata_viewNode refreshBrotherNodeIndex];
    }
}

- (void)setSensorsdata_viewNode:(SAViewNode *)sensorsdata_viewNode {
    objc_setAssociatedObject(self, kSAViewNodePropertyName, sensorsdata_viewNode, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SAViewNode *)sensorsdata_viewNode {
    return objc_getAssociatedObject(self, kSAViewNodePropertyName);
}

/// 刷新节点位置信息
- (void)sensorsdata_refreshIndex {
    if (self.sensorsdata_viewNode) {
        [self.sensorsdata_viewNode refreshIndex];
    }
}

@end

@implementation UITableViewCell(SAVisualProperties)

- (void)sensorsdata_visualize_prepareForReuse {
    [self sensorsdata_visualize_prepareForReuse];

    // 重用后更新 indexPath
    [self sensorsdata_refreshIndex];
}

@end

@implementation UICollectionViewCell(SAVisualProperties)

- (void)sensorsdata_visualize_prepareForReuse {
    [self sensorsdata_visualize_prepareForReuse];

    // 重用后更新 indexPath
    [self sensorsdata_refreshIndex];
}

@end


@implementation UITableViewHeaderFooterView(SAVisualProperties)

- (void)sensorsdata_visualize_prepareForReuse {
    [self sensorsdata_visualize_prepareForReuse];

    // 重用后更新 index
    [self sensorsdata_refreshIndex];
}

@end
