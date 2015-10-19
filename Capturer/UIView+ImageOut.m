//
//  UIView+ImageOut.m
//  TheMovieDB
//
//  Created by Li Hejun on 15/10/20.
//  Copyright © 2015年 iKode Ltd. All rights reserved.
//

#import "UIView+ImageOut.h"
#import <objc/runtime.h>
static const void *SnapshotKey = &SnapshotKey;
static const void *SnaptimeKey = &SnaptimeKey;
static const void *ImageDiffKey = &ImageDiffKey;
@implementation UIView (ImageOut)
@dynamic snapshot, snaptime, imageDiff;

- (UIImage *)snapshot {
    return objc_getAssociatedObject(self, SnapshotKey);
}

- (void)setSnapshot:(UIImage *)snapshot {
    objc_setAssociatedObject(self, SnapshotKey, snapshot, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)snaptime {
    return objc_getAssociatedObject(self, SnaptimeKey);
}

- (void)setSnaptime:(NSNumber *)snaptime {
    objc_setAssociatedObject(self, SnaptimeKey, snaptime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)imageDiff {
    return objc_getAssociatedObject(self, ImageDiffKey);
}

- (void)setImageDiff:(NSNumber *)imageDiff {
    objc_setAssociatedObject(self, ImageDiffKey, imageDiff, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
