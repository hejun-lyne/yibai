//
//  CLVideoEncoder.h
//  TheMovieDB
//
//  Created by lihejun on 15/10/19.
//  Copyright © 2015年 iKode Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLVideoEncoder : NSObject
+ (instancetype)sharedInstanceWithSize:(CGSize)size;
- (BOOL)encodeImage:(UIImage*)image needTransfrom:(BOOL)flag;
- (void)stop;
@end
