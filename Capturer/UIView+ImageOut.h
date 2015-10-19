//
//  UIView+ImageOut.h
//  TheMovieDB
//
//  Created by Li Hejun on 15/10/20.
//  Copyright © 2015年 iKode Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (ImageOut)
@property (nonatomic, strong)UIImage *snapshot;
@property (nonatomic, strong)NSNumber *snaptime;
@property (nonatomic, strong)NSNumber *imageDiff;
@end
