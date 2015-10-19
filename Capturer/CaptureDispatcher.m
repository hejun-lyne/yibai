//
//  CaptureDispatcher.m
//  TheMovieDB
//
//  Created by lihejun on 15/10/19.
//  Copyright © 2015年 iKode Ltd. All rights reserved.
//

#import "CaptureDispatcher.h"
#import "CLVideoEncoder.h"
#import "UIView+ImageOut.h"

@implementation CaptureDispatcher
{
    dispatch_queue_t _introQueue; // 排期队列
    dispatch_queue_t _queue; // 执行对了
    dispatch_queue_t _exitQueue; // 退出队列
    dispatch_queue_t _detectQueue; // 检测队列
}

+ (instancetype)sharedInstance {
    static CaptureDispatcher *_dispatcher = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dispatcher = [[CaptureDispatcher alloc] init];
    });
    return _dispatcher;
}

- (id)init {
    self = [super init];
    if (self) {
        _introQueue = dispatch_queue_create("com.baidu.carlife.captureIntroQueue", DISPATCH_QUEUE_SERIAL);
        _queue = dispatch_queue_create("com.baidu.carlife.captureQueue", DISPATCH_QUEUE_CONCURRENT);
        _exitQueue = dispatch_queue_create("com.baidu.carlife.captureMainQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)captureTableView:(UITableView *)tableView {
    for (UIView *view in tableView.subviews) {
        if (view.hidden) {
            view.snapshot = nil; // clear
        }
    }
    dispatch_group_t group = dispatch_group_create(); // make a group
    for (UITableViewCell *cell in tableView.visibleCells) {
        dispatch_group_async(group, _queue, ^(){
            // Do something that takes a while
            CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
            BOOL willCapture = NO;
            if (!cell.snapshot || [cell.imageDiff intValue] > 0) {
                // will capture
                willCapture = YES;
            } else {
                // make a chance
//                int chance = [self getRandomNumber:0 to:100];
//                willCapture = chance > 80;
            }
            if (willCapture) {
                UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0);
                [cell drawViewHierarchyInRect:cell.bounds afterScreenUpdates:NO];
                UIImage *captured = UIGraphicsGetImageFromCurrentImageContext();
                if (!cell.snapshot) {
                    cell.imageDiff = @(1);
                } else {
//                    cell.imageDiff = @(1);
                    cell.imageDiff = @(ABS(UIImageJPEGRepresentation(cell.snapshot, 0.1).length - UIImageJPEGRepresentation(captured, 0.1).length));
                }
                cell.snapshot = captured;
                UIGraphicsEndImageContext();
            }
            CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
            cell.snaptime = @(end);
            NSLog(@"---------- cell snapshot diff %f", end - start);
        });
    }
    dispatch_group_notify(group, _exitQueue, ^(){
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        UIGraphicsBeginImageContextWithOptions(tableView.bounds.size, NO, 0);
        for (UIView *cell in tableView.visibleCells) {
            CGRect r = cell.frame;
            r.origin.x -= tableView.contentOffset.x;
            r.origin.y -= tableView.contentOffset.y;
            [cell.snapshot drawInRect:r];
        }
        tableView.snapshot = UIGraphicsGetImageFromCurrentImageContext();
        [[CLVideoEncoder sharedInstanceWithSize:tableView.snapshot.size] encodeImage:tableView.snapshot needTransfrom:NO];
        UIGraphicsEndImageContext();
        CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
        NSLog(@"--- table snapshot diff %f", end - start);
        // 完成之后继续下一帧
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.03 * NSEC_PER_SEC);
        dispatch_after(popTime, _introQueue, ^(void){
            [self captureTableView:tableView];
        });
        // 计算差异化
        
    });
}

-(int)getRandomNumber:(int)from to:(int)to {
    return(int)(from + arc4random() % (to-from+1));
}

- (void)detectViewTree:(UITableView *)tableView {
    
}

@end
