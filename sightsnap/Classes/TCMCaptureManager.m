//
//  TCMCaptureManager.m
//  sightsnap
//
//  Created by Dominik Wagner on 27.03.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "TCMCaptureManager.h"



@interface TCMCaptureManager () {
    CVImageBufferRef _currentCVImageBuffer;
}
@property (nonatomic, strong) QTCaptureSession *captureSession;
@property (nonatomic, strong) QTCaptureDecompressedVideoOutput *videoOutput;
@property (nonatomic, strong) NSURL *fileOutputURL;
@property (nonatomic, strong) QTCaptureDevice *selectedCaptureDevice;
@property (nonatomic, strong) QTCaptureDeviceInput *videoInput;
@property (nonatomic, copy) id completionBlock;
@property (nonatomic, copy) id drawingBlock;
@property (nonatomic) NSInteger framesToSkip;
@property (nonatomic) BOOL grabNextArrivingImage;

@property (nonatomic, strong) AVCaptureSession *avCaptureSession;
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
		self.skipFrames = 2; // with a frame cap of 6 per sec, this should be enough for the average cam
    }
    return self;
}

- (void)teardownCaptureSession {
	[self.captureSession stopRunning];
	if (self.videoOutput) {
		[self.captureSession removeOutput:self.videoOutput];
		self.videoOutput.delegate = nil;
		self.videoOutput = nil;
	}
	if (self.videoInput) {
		[self.captureSession removeInput:self.videoInput];
		[self.videoInput.device close];
	}
	self.captureSession = nil;
}

- (void)bringUpCaptureSession {
	QTCaptureSession *session;
	session = [[QTCaptureSession alloc] init];
	self.captureSession = session;
	
	NSError *error;
	BOOL success;
	QTCaptureDeviceInput  *videoDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:self.selectedCaptureDevice];
	success = [session addInput:videoDeviceInput error:&error];
	if (!success) {
		NSLog(@"%s - error adding the video input: %@",__FUNCTION__,error);
		[self.selectedCaptureDevice close];
	} else {
		self.videoInput = videoDeviceInput;
		
		// Create an object for outputing the video
		// The input will tell the session object that it has taken
		// some data, which will in turn send this to the output
		// object, which has a delegate that you defined
		QTCaptureDecompressedVideoOutput *output = [[QTCaptureDecompressedVideoOutput alloc] init];
		
		// adjustments because we only take stills
		output.automaticallyDropsLateVideoFrames = YES; // we don't care if they drop if we are slow, we only want stills anyway
		output.minimumVideoFrameInterval = 1.0 / 6; // don't do more than 6 frames to cap load we generate and also to allow to captures stills from more than one cam!
		
		if (self.maxWidth > 0 && self.maxHeight > 0) {
			[output setPixelBufferAttributes:@{
					(id)kCVPixelBufferWidthKey : @(self.maxWidth),
					(id)kCVPixelBufferHeightKey : @(self.maxHeight)
			 }];
		}
		
		// This is the delegate. Note the
		// captureOutput:didOutputVideoFrame...-method of this
		// object. That is the method which will be called when
		// a photo has been taken.
		[output setDelegate:self];
		
		// Add the output-object for the session
		success = [session addOutput:output error:&error];
		
		if (!success) {
			NSLog(@"Did succeed in connecting output to session: %d", success);
			NSLog(@"Error: %@", [error localizedDescription]);
		} else {
			self.videoOutput = output;
			self.currentImageBuffer = nil;
		}
	}
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

- (QTCaptureDevice *)defaultVideoDevice {
	QTCaptureDevice *result = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
	if (!result) {
		result = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeMuxed];
	}
	return result;
}

- (NSArray *)availableVideoDevices {
    NSMutableArray *videoDevices = [NSMutableArray new];
    [videoDevices addObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]];
    [videoDevices addObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeMuxed]];
    [videoDevices addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo]];
    [videoDevices addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed]];
    return videoDevices;
}

- (void)setCurrentVideoDevice:(QTCaptureDevice *)aVideoDevice {
    BOOL success = NO;
    NSError *error;
	
	if (self.captureSession) {
		[self teardownCaptureSession];
	}
	
    success = [aVideoDevice open:&error];
    if (!success) {
        NSLog(@"%s - error opening the video input device: %@",__FUNCTION__,error);
    } else {
        self.selectedCaptureDevice = aVideoDevice;
		[self bringUpCaptureSession];
    }
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

- (BOOL)writeCGImage:(CGImageRef)aCGImageRef toURL:(NSURL *)aFileURL {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"]; //the date format for EXIF dates as from http://www.abmt.unibas.ch/dokumente/ExIF.pdf
    NSString *EXIFFormattedCreatedDate = [dateFormatter stringFromDate:[NSDate new]]; //use the date formatter to get a string from the date we were passed in the EXIF format

    
    NSDictionary *exifDictionary = @{
        (__bridge NSString *)kCGImagePropertyExifDateTimeOriginal : EXIFFormattedCreatedDate,
        (__bridge NSString *)kCGImagePropertyExifMakerNote : self.selectedCaptureDevice.localizedDisplayName
    };
    
    NSDictionary *tiffDictionary = @{
        (__bridge NSString *)kCGImagePropertyTIFFModel : self.selectedCaptureDevice.localizedDisplayName,
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


// QTCapture delegate method, called when a frame has been loaded by the camera
- (void)captureOutput:(QTCaptureOutput *)aCaptureOutput didOutputVideoFrame:(CVImageBufferRef)aVideoFrame withSampleBuffer:(QTSampleBuffer *)aSampleBuffer fromConnection:(QTCaptureConnection *)aConnection {

	// only grab the image if we are interested
	if (!self.grabNextArrivingImage) {
		return;
	}
	
	// skip frames to give webcam time if needed
    if (self.framesToSkip > 0) {
        self.framesToSkip = self.framesToSkip - 1;
        return;
    }
	    
    self.currentImageBuffer = aVideoFrame;
	self.grabNextArrivingImage = NO; // we have our frame
    
    // As stated above, this method will be called on another thread, so
    // we perform the selector that handles the image on the main thread
    [self performSelectorOnMainThread:@selector(didGrabImage) withObject:nil waitUntilDone:NO];
}

    

@end
