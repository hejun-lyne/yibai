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
#import "NSObject+FBKVOController.h"

#define MAX_OUTPUT_VIEWS 20
#define OUTPUT_VIEWTREE_LEVEL 3 //如果超过3个层级，可以认为是包含简单子视图的复杂视图，直接绘制即可

@interface FillArea : NSObject
@property(nonatomic, strong)UIView *view;
@property(nonatomic, assign)CGRect rect;
@end
@implementation FillArea
- (id)initWithView:(UIView *)view {
    self = [super init];
    if (self) {
        self.view = view;
        self.rect = view.frame;
    }
    return self;
}
@end
@implementation CaptureDispatcher
{
    dispatch_queue_t _introQueue; // 排期队列
    dispatch_queue_t _queue; // 执行队列
    dispatch_queue_t _exitQueue; // 退出队列
    
    UIView *_startView;
    NSMutableArray *_outputViews;
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
        _outputViews = [NSMutableArray array];
    }
    return self;
}

static CFAbsoluteTime startTime;
- (void)captureView:(UIView *)rootView {
    if (rootView) {
        _startView = rootView;
    }
    // 遍历视图树
    [self traverseViews:_startView];
    // 标记输出
    [_outputViews removeAllObjects];
    for (UIView *view in _startView.subviews) {
        [self markOutput:view];
    }
    
    startTime = CFAbsoluteTimeGetCurrent();
    // 暂时不处理背景的情况
    dispatch_group_t group = dispatch_group_create(); // make a group
    for (id obj in _outputViews) {
        if (![obj isKindOfClass:[UIView class]]) {
            continue;
        }
        UIView *view = (UIView *)obj;
        dispatch_group_async(group, _queue, ^(){
//            CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
            
            if (!view.clcapSnapshot
                || [view.clcapDiff intValue] > 0
                || view.clcapChanged) {
                // will capture
                UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0);
                [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
                UIImage *captured = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                if (!view.clcapSnapshot) {
                    view.clcapDiff = @(1);
                } else {
                    view.clcapDiff = @(ABS(UIImageJPEGRepresentation(view.clcapSnapshot, 0.1).length - UIImageJPEGRepresentation(captured, 0.1).length));
                    if ([view.clcapDiff intValue] == 0) {
                        // reset
                        view.clcapChanged = nil;
                    }
                }
                view.clcapSnapshot = captured;
                
            }
            CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
            view.clcapTime = @(end);
//            NSLog(@"---------- cell snapshot diff %f", end - start);
        });
    }
    dispatch_group_notify(group, _exitQueue, ^(){
//        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        UIGraphicsBeginImageContextWithOptions(_startView.bounds.size, NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        for (id obj in _outputViews) {
            if ([obj isKindOfClass:[UIView class]]) {
                UIView *view = (UIView *)obj;
                CGRect r = [view.superview convertRect:CGRectFromString(view.clcapFrame) toView:_startView]; // 在根视图中的位置
                [view.clcapSnapshot drawInRect:r];
            } else if ([obj isKindOfClass:[FillArea class]]) {
                FillArea *fill = (FillArea *)obj;
                CGContextSetFillColorWithColor(context, fill.view.backgroundColor.CGColor);
                CGContextFillRect(context, [fill.view.superview convertRect:fill.rect toView:_startView]);
            }
            
        }
        UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
        NSLog(@"--- table snapshot diff %f", end - startTime);
        // 完成之后继续下一帧
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.03 * NSEC_PER_SEC);
        dispatch_after(popTime, _introQueue, ^(void){
            [self captureView:nil];
        });
        // 视频编码
        [[CLVideoEncoder sharedInstanceWithSize:snapshot.size] encodeImage:snapshot needTransfrom:NO];
        
        
    });
}

/**
 * @abstract 深度遍历多叉树
 * @param rootView 根节点
 * @return 视图是否已改变
 */
- (BOOL)traverseViews:(UIView *)rootView {
    if ([[rootView description] hasPrefix:@"<_"]) { // hidden view
        return NO;
    }
    if (rootView.hidden) {
        // 如果是隐藏视图，需要清空截图
        rootView.clcapSnapshot = nil;
        return NO;
    }
    // 进行标记
    if (!rootView.clcapMarked) {
        // 未标记，直接标记
        rootView.clcapMarked = @"YES";
        rootView.clcapChanged = @"YES";
        
        // 监控hidden和alpha，后续可能根据需要添加
        void (^changedBlock)(id, id obj, NSDictionary*) = ^(UIView *view, id obj, NSDictionary *change){
            view.clcapChanged = @"YES";
            // 需要向上更新
            UIView *parentView = view.superview;
            while (parentView.superview) {
                if (!parentView.clcapChanged) {
                    // 找到最近一个输出视图
                    parentView.clcapChanged = @"YES";
                    break;
                } else {
                    parentView = parentView.superview;
                }
            }
        };
        [rootView.KVOController observe:rootView keyPath:@"hidden" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew block:changedBlock];
        [rootView.KVOController observe:rootView keyPath:@"alpha" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew block:changedBlock];
        [rootView.KVOController observe:rootView keyPath:@"backgroundColor" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew block:changedBlock];
//        [rootView.KVOController observe:rootView keyPath:@"frame" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew block:changedBlock];
    }
    
    for (UIView *view in [rootView subviews])
    {
        // 遍历子视图
        if (!view.clcapChanged && [self traverseViews:view]) {
            view.clcapChanged = @"YES";
        }
    }
    return rootView.clcapChanged;
}

// 标记需要绘制的视图
- (void)markOutput:(UIView *)rootView {
    if (rootView.hidden // 视图隐藏
        || [[rootView description] hasPrefix:@"<_"]
        ) {
        return;
    }
    
    if ([_outputViews count] >= MAX_OUTPUT_VIEWS // 超过并发数目
        || [self viewTreeLevels:rootView] <= OUTPUT_VIEWTREE_LEVEL) { // 小于阈值
        [_outputViews addObject:rootView];
        rootView.clcapFrame = NSStringFromCGRect(rootView.frame);
        return;
    } else {
        // 遍历子视图
        if (rootView.backgroundColor && rootView.backgroundColor != [UIColor clearColor]) {
            // 只支持纯色
            FillArea *fill = [[FillArea alloc] initWithView:rootView];
            [_outputViews addObject:fill];
        }
        for (UIView *view in rootView.subviews) {
            [self markOutput:view];
        }
    }
}

// 找到该树的最深层级
- (int)viewTreeLevels:(UIView *)view {
    int level = 0;
    for (UIView *subview in view.subviews) {
        int sublevel = [self viewTreeLevels:subview];
        if (sublevel > level) {
            level = sublevel;
        }
    }
    return level + 1;
}

@end
