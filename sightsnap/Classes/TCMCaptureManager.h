//
//  TCMCaptureManager.h
//  sightsnap
//
//  Created by Dominik Wagner on 27.03.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>

typedef void (^TCMCaptureQuartzAction)(CGContextRef aContext, CGRect aFrame);

@interface TCMCaptureManager : NSObject
@property (nonatomic) CGFloat jpegQuality;
@property (nonatomic) NSInteger skipFrames;
@property (nonatomic) NSInteger maxWidth;
@property (nonatomic) NSInteger maxHeight;
@property (nonatomic) BOOL shouldKeepCaptureSessionOpen;

+ (instancetype)captureManager;

- (void)teardownCaptureSession;

- (QTCaptureDevice *)defaultVideoDevice;
- (NSArray *)availableVideoDevices;
- (void)setCurrentVideoDevice:(QTCaptureDevice *)aVideoDevice;
- (void)setImageDrawingBlock:(TCMCaptureQuartzAction)drawingBlock;
- (void)saveFrameToURL:(NSURL *)aFileURL completion:(void (^)())aCompletion;
@end
