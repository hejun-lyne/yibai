//
//  CLVideoEncoder.m
//  TheMovieDB
//
//  Created by lihejun on 15/10/19.
//  Copyright © 2015年 iKode Ltd. All rights reserved.
//

#import "CLVideoEncoder.h"
#import <AVFoundation/AVFoundation.h>

@implementation CLVideoEncoder
{
    AVAssetWriter *_writer;
    AVAssetWriterInput *_writerInput;
    AVAssetWriterInputPixelBufferAdaptor *_adaptor;
    CFAbsoluteTime _startTime;
}

+ (instancetype)sharedInstanceWithSize:(CGSize)size {
    static CLVideoEncoder *_dispatcher = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dispatcher = [[CLVideoEncoder alloc] initWithSize:size];
    });
    return _dispatcher;
}

- (void)stop {
    [_writerInput markAsFinished];
    [_writer finishWritingWithCompletionHandler:^(void){
        dispatch_sync(dispatch_get_main_queue(), ^(void){
            [[[UIAlertView alloc] initWithTitle:@"Video Recording Stopped!" message:@"sotopped" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil, nil] show];
        });
    }];
}

- (id)initWithSize:(CGSize)size {
    self = [super init];
    if (self) {
        [self initEncoder:size];
    }
    return self;
}

- (void)initEncoder:(CGSize)size {
    NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSLog(@"%@", documentsDirectoryPath);
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:nil];
    for (NSString *tString in dirContents) {
        if ([tString isEqualToString:@"capture.mp4"])
        {
            [[NSFileManager defaultManager]removeItemAtPath:[NSString stringWithFormat:@"%@/%@",documentsDirectoryPath,tString] error:nil];
            
        }
    }
    NSString *file = [documentsDirectoryPath stringByAppendingPathComponent:@"capture.mp4"];
    NSError *error;
    _writer = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:file] fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(_writer);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    
    _writerInput = [AVAssetWriterInput
                                             assetWriterInputWithMediaType:AVMediaTypeVideo
                                             outputSettings:videoSettings];
    
    _adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                    assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_writerInput
                                                     sourcePixelBufferAttributes:nil];
    
    NSParameterAssert(_writerInput);
    NSParameterAssert([_writer canAddInput:_writerInput]);
    _writerInput.expectsMediaDataInRealTime = YES;
    [_writer addInput:_writerInput];
}

-(BOOL)encodeImage:(UIImage*)image needTransfrom:(BOOL)flag
{
    if (_writer.status == AVAssetWriterStatusCompleted) {
        return NO;
    } else if (_writer.status == AVAssetWriterStatusUnknown)
    {
        _startTime = CFAbsoluteTimeGetCurrent();
        CFAbsoluteTime interval = (CFAbsoluteTimeGetCurrent() - _startTime) * 1000;
        CMTime currentSampleTime = CMTimeMake((int)interval, 1000);
        
        //        CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        [_writer startWriting];
        [_writer startSessionAtSourceTime:currentSampleTime];
    }
    if (_writer.status == AVAssetWriterStatusFailed)
    {
        NSLog(@"writer error %@", _writer.error.localizedDescription);
        return NO;
    }
    if (_writerInput.readyForMoreMediaData == YES)
    {
        //        [_writerInput appendSampleBuffer:sampleBuffer];
        
        CGSize size = CGSizeMake(image.size.width* image.scale, image.size.height* image.scale);
        CVPixelBufferRef buffer = NULL;
        buffer = [self pixelBufferFromCGImage:[image CGImage] size:size needTransfrom:flag];
        
        if (buffer)
        {
            CFAbsoluteTime interval = (CFAbsoluteTimeGetCurrent() - _startTime) * 1000;
            CMTime currentSampleTime = CMTimeMake((int)interval, 1000);
            
            //if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame, 25)])
            if(![_adaptor appendPixelBuffer:buffer withPresentationTime:currentSampleTime])
                printf("FAIL");
            
            CFRelease(buffer);
            buffer = NULL;
            
            if (interval > 30000) {
                // 只录制30秒
                [self stop];
            }
            return YES;
        }
    }
    return YES;
}

-(CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size needTransfrom:(BOOL)flag
{
    
#ifdef OUTPUT_ENCODE_TIME
    CFAbsoluteTime interval1 = CFAbsoluteTimeGetCurrent();
#endif
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)options, &pxbuffer);
    
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    
    unsigned char *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, 4*size.width, rgbColorSpace, kCGImageAlphaPremultipliedFirst);
    
    NSParameterAssert(context);
    
    if (flag)//需要变换
    {
        // 奇怪的尺寸啊！！
        float offset = ((float)CGImageGetWidth(image))/CGImageGetHeight(image);
        CGContextTranslateCTM(context, 0, CGImageGetHeight(image)*offset);
        CGContextRotateCTM(context, -M_PI_2);
    }
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    
#if 0 //调整颜色分量
    
    CFAbsoluteTime interval2 = CFAbsoluteTimeGetCurrent();
    int bitmapOffest = 0;
    for(int row = 0; row < size.width; row ++)
        for(int column = 0; column < size.height;column ++)
        {
            float r = (unsigned int)pxdata[bitmapOffest];
            float g = (unsigned int)pxdata[bitmapOffest + 1];
            //            float b = (unsigned int)pxdata[bitmapOffest + 2];
            //            float a = (unsigned int)pxdata[bitmapOffest + 3];
            
            pxdata[bitmapOffest] = r>10? r -10:0;
            pxdata[bitmapOffest + 1] = g>15?g -15:0;
            
            bitmapOffest +=4;
            
        }
    
    CFAbsoluteTime interval3 = CFAbsoluteTimeGetCurrent() - interval2;
    NSLog(@"pixelBufferFromCGImage 1111111= %f",interval3);
#endif
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
#ifdef OUTPUT_ENCODE_TIME
    CFAbsoluteTime interval = CFAbsoluteTimeGetCurrent() - interval1;
    NSLog(@"pixelBufferFromCGImage = %f",interval);
#endif
    return pxbuffer;
}
@end
