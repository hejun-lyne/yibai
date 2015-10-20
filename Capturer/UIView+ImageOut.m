//
//  UIView+ImageOut.m
//  TheMovieDB
//
//  Created by Li Hejun on 15/10/20.
//  Copyright © 2015年 iKode Ltd. All rights reserved.
//

#import "UIView+ImageOut.h"
#import <objc/runtime.h>
static const void *CLCAPMarkedKey = &CLCAPMarkedKey;
static const void *CLCAPChangedKey = &CLCAPChangedKey;
static const void *CLCAPOutputKey = &CLCAPMarkedKey;
static const void *CLCAPSnapshotKey = &CLCAPSnapshotKey;
static const void *CLCAPFrameKey = &CLCAPFrameKey;
static const void *CLCAPTimeKey = &CLCAPTimeKey;
static const void *CLCAPDiffKey = &CLCAPDiffKey;
@implementation UIView (ImageOut)
@dynamic clcapMarked, clcapChanged, clcapOutput, clcapSnapshot, clcapFrame, clcapTime, clcapDiff;

- (NSString *)clcapMarked {
    return objc_getAssociatedObject(self, CLCAPMarkedKey);
}

- (void)setClcapMarked:(NSString *)clcapMarked {
    objc_setAssociatedObject(self, CLCAPMarkedKey, clcapMarked, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)clcapChanged {
    return objc_getAssociatedObject(self, CLCAPChangedKey);
}

- (void)setClcapChanged:(NSString *)clcapChanged {
    objc_setAssociatedObject(self, CLCAPChangedKey, clcapChanged, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)clcapOutput {
    return objc_getAssociatedObject(self, CLCAPOutputKey);
}

- (void)setClcapOutput:(NSString *)clcapOutput {
    objc_setAssociatedObject(self, CLCAPOutputKey, clcapOutput, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)clcapSnapshot {
    return objc_getAssociatedObject(self, CLCAPSnapshotKey);
}

- (NSString *)clcapFrame {
    return objc_getAssociatedObject(self, CLCAPFrameKey);
}

- (void)setClcapFrame:(NSString *)clcapFrame {
    objc_setAssociatedObject(self, CLCAPFrameKey, clcapFrame, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setClcapSnapshot:(UIImage *)clcapSnapshot {
    objc_setAssociatedObject(self, CLCAPSnapshotKey, clcapSnapshot, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)clcapTime {
    return objc_getAssociatedObject(self, CLCAPTimeKey);
}

- (void)setClcapTime:(NSNumber *)clcapTime {
    objc_setAssociatedObject(self, CLCAPTimeKey, clcapTime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)clcapDiff {
    return objc_getAssociatedObject(self, CLCAPDiffKey);
}

- (void)setClcapDiff:(NSNumber *)clcapDiff {
    objc_setAssociatedObject(self, CLCAPDiffKey, clcapDiff, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
