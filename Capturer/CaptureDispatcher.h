//
//  CaptureDispatcher.h
//  TheMovieDB
//
//  Created by lihejun on 15/10/19.
//  Copyright © 2015年 iKode Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CaptureDispatcher : NSObject

+ (instancetype)sharedInstance;

- (void)captureView:(UIView *)rootView;

@end
