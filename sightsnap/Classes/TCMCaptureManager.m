//
//  TCMCaptureManager.m
//  sightsnap
//
//  Created by Dominik Wagner on 27.03.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "TCMCaptureManager.h"



@interface TCMCaptureManager () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    CVImageBufferRef _currentCVImageBuffer;
}
@property (nonatomic, strong) NSURL *fileOutputURL;
@property (nonatomic, copy) id completionBlock;
@property (nonatomic, copy) id drawingBlock;
@property (nonatomic) NSInteger framesToSkip;
@property (nonatomic) BOOL grabNextArrivingImage;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *selectedCaptureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterInput;
@property (nonatomic) CMTime nextFrameTime;

@end

@implementation TCMCaptureManager

+ (instancetype)captureManager {
    static dispatch_once_t predicate;
    static TCMCaptureManager *S_singleton = nil;
    dispatch_once(&predicate, ^{
        S_singleton = [TCMCaptureManager new];
    });
    return S_singleton;
}

- (id)init {
    self = [super init];
    if (self) {
        self.jpegQuality = 0.8;
		self.skipFrames = 5; // with a frame cap of 6 per sec, this should be enough for the average cam
    }
    return self;
}

- (void)teardownCaptureSession {
	[self.captureSession stopRunning];
	if (self.videoDataOutput) {
		[self.captureSession removeOutput:self.videoDataOutput];
        [self.videoDataOutput setSampleBufferDelegate:nil queue:nil];
		self.videoDataOutput = nil;
	}
	if (self.videoInput) {
		[self.captureSession removeInput:self.videoInput];
	}
    [self teardownAssetWriter];
	self.captureSession = nil;
}

- (void)bringUpCaptureSession {
	AVCaptureSession *session;
	session = [[AVCaptureSession alloc] init];
	self.captureSession = session;

	NSError *error;

    // config
    if ([self.selectedCaptureDevice lockForConfiguration:NULL]) {
        [self.selectedCaptureDevice setActiveVideoMinFrameDuration:[self.selectedCaptureDevice.activeFormat maxFrameDurationLessThanTimeInterval:1.0 / 12.0]];
        [self.selectedCaptureDevice unlockForConfiguration];
    }

    AVCaptureDeviceInput  *videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.selectedCaptureDevice error:&error];
    
	[session addInput:videoDeviceInput];

    self.videoInput = videoDeviceInput;
		
    // Create an object for outputing the video
    // The input will tell the session object that it has taken
    // some data, which will in turn send this to the output
    // object, which has a delegate that you defined
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:dispatch_queue_create("buffer_capture_queue",DISPATCH_QUEUE_SERIAL)];
	[session addOutput:output];
    self.videoDataOutput = output;
    self.currentImageBuffer = nil;
}

- (void)dealloc {
	[self teardownCaptureSession];
    self.currentImageBuffer = nil;
}

- (void)setCurrentImageBuffer:(CVImageBufferRef)aImageBuffer {
    if (aImageBuffer) {
        CVBufferRetain(aImageBuffer);
    }
    if (_currentCVImageBuffer) {
        CVBufferRelease(_currentCVImageBuffer);
    }
    _currentCVImageBuffer = aImageBuffer;
}

- (CVImageBufferRef)currentImageBuffer {
    return _currentCVImageBuffer;
}

- (AVCaptureDevice *)defaultVideoDevice {
	AVCaptureDevice *result = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	if (!result) {
		result = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeMuxed];
	}
	return result;
}

- (NSArray *)availableVideoDevices {
    NSMutableArray *videoDevices = [NSMutableArray new];
    [videoDevices addObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]];
    [videoDevices addObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeMuxed]];
    return videoDevices;
}

- (void)setCurrentVideoDevice:(AVCaptureDevice *)aVideoDevice {
	if (self.captureSession) {
		[self teardownCaptureSession];
	}

    self.selectedCaptureDevice = aVideoDevice;
    [self bringUpCaptureSession];
}
    
- (void)saveFrameToURL:(NSURL *)aFileURL completion:(void (^)())aCompletion {
    self.fileOutputURL = aFileURL;
    self.completionBlock = (id)aCompletion;
	self.grabNextArrivingImage = YES;

	if (!self.captureSession.isRunning) {
		self.framesToSkip = self.skipFrames;
		[self.captureSession startRunning];
	}
}

- (void)setupAssetsWriterForURL:(NSURL *)aFileURL {
    NSError *error;
    // delete the file if there
    [[NSFileManager defaultManager] removeItemAtURL:aFileURL error:nil];
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:aFileURL fileType:AVFileTypeMPEG4 error:&error];
    if (!assetWriter) {
        NSLog(@"%s %@",__FUNCTION__,error);
    } else {
//        assetWriter.shouldOptimizeForNetworkUse = YES;
        assetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, 1000.);
        
        AVAssetWriterInput *input = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:@{AVVideoCodecKey:AVVideoCodecH264, AVVideoHeightKey : @(720), AVVideoWidthKey: @(1280), AVVideoScalingModeKey : AVVideoScalingModeResizeAspect}];
        [input setExpectsMediaDataInRealTime:YES];
        [assetWriter addInput:input];
        self.assetWriter = assetWriter;
        self.assetWriterInput = input;
        self.nextFrameTime = kCMTimeZero;
        [assetWriter startWriting];
        [assetWriter startSessionAtSourceTime:self.nextFrameTime];
    }
}

- (void)teardownAssetWriterWithCompletionHandler:(dispatch_block_t)aCompletionHandler {
    AVAssetWriter *writer = self.assetWriter;
    if (writer) {
        [self.assetWriterInput markAsFinished];
        dispatch_block_t finishBlock = ^{
            // this use here also retains the writer in the block
            // if the writer doesn't get rid of the completion handler after firing it
            // this will cause a leak - however, not relevant as long as we only write one movie in this command line util
            // and we need to prolong the writers life to actually fire the finishBlock anyways
            if (writer.status != AVAssetWriterStatusCompleted) {
                NSDictionary *statusDescription = @{
                    @(AVAssetWriterStatusFailed) : @"Failed",
                    @(AVAssetWriterStatusCancelled) : @"Cancelled",
                    @(AVAssetWriterStatusUnknown) : @"Unknown",
                    @(AVAssetWriterStatusWriting) : @"Writing",
                };
                printf("Assets written with status: %ld - %s\n", (long)writer.status, [statusDescription[@(writer.status)] UTF8String]);
            }
            if (aCompletionHandler) {
                aCompletionHandler();
            }
        };
        if (writer.status == AVAssetWriterStatusFailed) {
            puts([[NSString stringWithFormat:@"Movie writing failed: (%@)\n",[writer.error localizedDescription]] UTF8String]);
            if (aCompletionHandler) {
                aCompletionHandler();
            }
        } else {
            [writer finishWritingWithCompletionHandler:finishBlock];
        }
        self.assetWriter = nil;
        self.assetWriterInput = nil;
    } else {
        if (aCompletionHandler) {
            dispatch_async(dispatch_get_main_queue(), aCompletionHandler);
        }
    }
}

- (void)teardownAssetWriter {
    [self teardownAssetWriterWithCompletionHandler:NULL];
}

- (BOOL)writeCGImage:(CGImageRef)aCGImageRef toURL:(NSURL *)aFileURL {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"]; //the date format for EXIF dates as from http://www.abmt.unibas.ch/dokumente/ExIF.pdf
    NSString *EXIFFormattedCreatedDate = [dateFormatter stringFromDate:[NSDate new]]; //use the date formatter to get a string from the date we were passed in the EXIF format

    
    NSDictionary *exifDictionary = @{
        (__bridge NSString *)kCGImagePropertyExifDateTimeOriginal : EXIFFormattedCreatedDate,
        (__bridge NSString *)kCGImagePropertyExifMakerNote : self.selectedCaptureDevice.localizedName
    };
    
    NSDictionary *tiffDictionary = @{
        (__bridge NSString *)kCGImagePropertyTIFFModel : self.selectedCaptureDevice.localizedName,
        (__bridge NSString *)kCGImagePropertyTIFFDateTime : EXIFFormattedCreatedDate
    };
    
    NSString *extension = [aFileURL pathExtension];
    CFStringRef type = kUTTypeJPEG;
    NSMutableDictionary *imageOptions = [@{(__bridge NSString *)kCGImagePropertyExifDictionary : exifDictionary,
                                         (__bridge NSString *)kCGImagePropertyTIFFDictionary : tiffDictionary,
                                         (__bridge NSString *)kCGImageDestinationMergeMetadata : @(YES)} mutableCopy];
    if ([@"png" caseInsensitiveCompare:extension] == NSOrderedSame) {
        type = kUTTypePNG;
    } else {
		if ([@"jp2" caseInsensitiveCompare:extension] == NSOrderedSame) {
			type = kUTTypeJPEG2000;
		}
        imageOptions[(__bridge NSString *)kCGImageDestinationLossyCompressionQuality] =  @(self.jpegQuality);
    }
	CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((__bridge CFURLRef)aFileURL, type, 1, nil);
	CGImageDestinationAddImage(imageDestination, aCGImageRef, (__bridge CFDictionaryRef)imageOptions);
	BOOL result = CGImageDestinationFinalize(imageDestination);
	CFRelease(imageDestination);
	return result;
}

- (void)didGrabImage {
    // Stop the session so we don't record anything more
	if (!self.shouldKeepCaptureSessionOpen) {
		[self.captureSession stopRunning];
	}
    
    // Convert the image to a NSImage with JPEG representation
    // This is a bit tricky and involves taking the raw data
    // and turning it into an NSImage containing the image
    // as JPEG
    
    CIImage *coreImage = [CIImage imageWithCVImageBuffer:self.currentImageBuffer];
    CGRect contextRect = CGRectZero;
    CGSize size = coreImage.extent.size;
	
	CGSize scaledSize = size;
	double scale = 1.0;
	if (self.maxWidth > 0 && scaledSize.width > self.maxWidth) {
		scale = self.maxWidth / scaledSize.width;
		scaledSize = CGSizeMake(ceil(scaledSize.width * scale), ceil(scaledSize.height * scale));
	}
	if (self.maxHeight > 0 && scaledSize.height > self.maxHeight) {
		scale = self.maxHeight / size.height;
		scaledSize = CGSizeMake(ceil(size.width * scale), ceil(size.height * scale));
	}
    contextRect.size = scaledSize;

    size_t bitsPerComponent = 8;
    size_t rowbytes = 4 * contextRect.size.width * bitsPerComponent / 8;
    static CGColorSpaceRef colorSpace = nil;
    if (!colorSpace) colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgContext = CGBitmapContextCreate(nil, CGRectGetWidth(contextRect),CGRectGetHeight(contextRect), bitsPerComponent, rowbytes, colorSpace, kCGImageAlphaPremultipliedFirst);
	CGContextSetInterpolationQuality(cgContext, kCGInterpolationHigh);
	// todo: investigate nice CI scale filter instead
    CIContext *context = [CIContext contextWithCGContext:cgContext options:nil];
    [context drawImage:coreImage inRect:contextRect fromRect:coreImage.extent];
    if (self.drawingBlock) {
        CGContextSaveGState(cgContext);
        ((TCMCaptureQuartzAction)self.drawingBlock)(cgContext, contextRect);
        CGContextRestoreGState(cgContext);
    }
    
//    CGImageRef cgImage = [context createCGImage:coreImage fromRect:coreImage.extent];
    CGImageRef cgImage = CGBitmapContextCreateImage(cgContext);
  
    [self writeCGImage:cgImage toURL:self.fileOutputURL];
    if (cgImage) CFRelease(cgImage);
    CGContextRelease(cgContext);
    
    self.currentImageBuffer = nil;
    
    void (^completionBlock)() = self.completionBlock;
    if (completionBlock) {
        completionBlock();
        self.completionBlock = nil;
    }
}

- (void)setImageDrawingBlock:(TCMCaptureQuartzAction)drawingBlock {
    self.drawingBlock = drawingBlock;
}

- (void)writeSampleBuffer:(CMSampleBufferRef)aSampleBuffer {
    if (self.assetWriter) {
        // retime sample info
        CMSampleTimingInfo timingInfo = kCMTimingInfoInvalid;
        CMTime frameDuration = CMTimeMakeWithSeconds(1./25, 1000);
        timingInfo.duration = frameDuration;
        timingInfo.presentationTimeStamp = self.nextFrameTime;
        CMSampleBufferRef stampedSampleBuffer = NULL;
        OSStatus err = CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, aSampleBuffer, 1, &timingInfo, &stampedSampleBuffer);
        if (err) return;
        [self.assetWriterInput appendSampleBuffer:stampedSampleBuffer];
        self.nextFrameTime = CMTimeAdd(self.nextFrameTime, frameDuration);
    }
}

// avcapture output method
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

	// only grab the image if we are interested
	if (!self.grabNextArrivingImage) {
		return;
	}
	
	// skip frames to give webcam time if needed
    if (self.framesToSkip > 0) {
        self.framesToSkip = self.framesToSkip - 1;
        return;
    }
	CVImageBufferRef aVideoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    self.currentImageBuffer = aVideoFrame;
	self.grabNextArrivingImage = NO; // we have our frame
    [self writeSampleBuffer:sampleBuffer];
    
    // As stated above, this method will be called on another thread, so
    // we perform the selector that handles the image on the main thread
    [self performSelectorOnMainThread:@selector(didGrabImage) withObject:nil waitUntilDone:NO];
}

    

@end
