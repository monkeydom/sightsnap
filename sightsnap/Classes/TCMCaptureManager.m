//
//  TCMCaptureManager.m
//  sightsnap
//
//  Created by Dominik Wagner on 27.03.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "TCMCaptureManager.h"

BOOL TCMCGImageWritePNGToURL(CGImageRef aCGImageRef, CFURLRef anURLRef) {
	CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL(anURLRef, kUTTypeJPEG, 1, nil);
	CGImageDestinationAddImage(imageDestination, aCGImageRef, nil);
	BOOL result = CGImageDestinationFinalize(imageDestination);
	CFRelease(imageDestination);
	return result;
}


@interface TCMCaptureManager () {
    CVImageBufferRef _currentCVImageBuffer;
}
@property (nonatomic, strong) QTCaptureSession *captureSession;
@property (nonatomic, strong) QTCaptureDecompressedVideoOutput *videoOutput;
@property (nonatomic, strong) NSURL *fileOutputURL;
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
        self.captureSession = [[QTCaptureSession alloc] init];
    }
    return self;
}

- (void)dealloc {
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

- (NSArray *)availableVideoDevices {
    NSMutableArray *videoDevices = [NSMutableArray new];
    [videoDevices addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo]];
    [videoDevices addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed]];
    return videoDevices;
}

- (void)setCurrentVideoDevice:(QTCaptureDevice *)aVideoDevice {
    BOOL success = NO;
    NSError *error;
    QTCaptureSession *session = self.captureSession;
    success = [aVideoDevice open:&error];
    if (!success) {
        NSLog(@"%s - error opening the video input device: %@",__FUNCTION__,error);
    } else {
        QTCaptureDeviceInput  *videoDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:aVideoDevice];
        success = [session addInput:videoDeviceInput error:&error];
        if (!success) {
            NSLog(@"%s - error adding the video input: %@",__FUNCTION__,error);
            [aVideoDevice close];
        } else {
            
            // Create an object for outputing the video
            // The input will tell the session object that it has taken
            // some data, which will in turn send this to the output
            // object, which has a delegate that you defined
            QTCaptureDecompressedVideoOutput *output = [[QTCaptureDecompressedVideoOutput alloc] init];
            
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
                self.currentImageBuffer = nil;
            }
        }
    }
}
    
- (void)saveFrameToURL:(NSURL *)aFileURL {
    self.fileOutputURL = aFileURL;
    [self.captureSession startRunning];
}

- (void)didGrabImage {
    // Stop the session so we don't record anything more
    [self.captureSession stopRunning];
    
    // Convert the image to a NSImage with JPEG representation
    // This is a bit tricky and involves taking the raw data
    // and turning it into an NSImage containing the image
    // as JPEG
    
    CIImage *coreImage = [CIImage imageWithCVImageBuffer:self.currentImageBuffer];
    CGRect contextRect = CGRectZero;
    CGSize size = coreImage.extent.size;
    contextRect.size = size;
    size_t bitsPerComponent = 8;
    size_t rowbytes = 4 * size.width * bitsPerComponent / 8;
    static CGColorSpaceRef colorSpace = nil;
    if (!colorSpace) colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgContext = CGBitmapContextCreate(nil, size.width, size.height, bitsPerComponent, rowbytes, colorSpace, kCGImageAlphaPremultipliedFirst);
    CIContext *context = [CIContext contextWithCGContext:cgContext options:nil];
//    [context drawImage:coreImage inRect:contextRect fromRect:coreImage.extent];
    
    CGImageRef cgImage = [context createCGImage:coreImage fromRect:coreImage.extent];
    
    TCMCGImageWritePNGToURL(cgImage, (__bridge CFURLRef)self.fileOutputURL);
    
    CGContextRelease(cgContext);
    
    self.currentImageBuffer = nil;
}

// QTCapture delegate method, called when a frame has been loaded by the camera
- (void)captureOutput:(QTCaptureOutput *)aCaptureOutput didOutputVideoFrame:(CVImageBufferRef)aVideoFrame withSampleBuffer:(QTSampleBuffer *)aSampleBuffer fromConnection:(QTCaptureConnection *)aConnection {
    // If we already have an image we should use that instead
    if (self.currentImageBuffer) return;
    
    self.currentImageBuffer = aVideoFrame;
    
    // As stated above, this method will be called on another thread, so
    // we perform the selector that handles the image on the main thread
    [self performSelectorOnMainThread:@selector(didGrabImage) withObject:nil waitUntilDone:NO];
}

    

@end
