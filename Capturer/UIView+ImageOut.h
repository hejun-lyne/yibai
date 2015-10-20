//
//  UIView+ImageOut.h
//  TheMovieDB
//
//  Created by Li Hejun on 15/10/20.
//  Copyright © 2015年 iKode Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (ImageOut)
// 是否已标记，主要用于检测新视图
@property (nonatomic, strong)NSString *clcapMarked;
// 是否已发生变化，该属性会向上传递
@property (nonatomic, strong)NSString *clcapChanged;
// 是否输出截图，直接调用该视图的方法drawViewHierarchyInRect:afterScreenUpdates:输入图像，不再遍历其子视图
@property (nonatomic, strong)NSString *clcapOutput;
// 当前保存截图
@property (nonatomic, strong)UIImage *clcapSnapshot;
// 截图时刻的frame
@property (nonatomic, strong)NSString *clcapFrame;
// 当前截图时间
@property (nonatomic, strong)NSNumber *clcapTime;
// 当前截图与上一截图之间的差异
@property (nonatomic, strong)NSNumber *clcapDiff;
@end
