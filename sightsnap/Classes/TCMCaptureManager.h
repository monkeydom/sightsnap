//
//  TCMCaptureManager.h
//  sightsnap
//
//  Created by Dominik Wagner on 27.03.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void (^TCMCaptureQuartzAction)(CGContextRef aContext, CGRect aFrame, NSDate *timestampTaken);

@interface TCMCaptureManager : NSObject
@property (nonatomic) CGFloat jpegQuality;
@property (nonatomic) NSInteger skipFrames;
@property (nonatomic) NSInteger maxWidth;
@property (nonatomic) NSInteger maxHeight;
@property (nonatomic) BOOL shouldKeepCaptureSessionOpen;

+ (instancetype)captureManager;

- (void)teardownCaptureSession;

- (AVCaptureDevice *)defaultVideoDevice;
- (NSArray *)availableVideoDevices;
- (void)setCurrentVideoDevice:(AVCaptureDevice *)aVideoDevice;
- (void)setImageDrawingBlock:(TCMCaptureQuartzAction)drawingBlock;
- (void)saveFrameToURL:(NSURL *)aFileURL completion:(void (^)())aCompletion;

- (void)setupAssetsWriterForURL:(NSURL *)aFileURL;
- (void)teardownAssetWriterWithCompletionHandler:(dispatch_block_t)aCompletionHandler;

@end
