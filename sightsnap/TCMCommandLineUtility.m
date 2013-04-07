//
//  TCMCommandLineUtility.m
//  sightsnap
//
//  Created by Dominik Wagner on 29.03.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "TCMCommandLineUtility.h"
#import <QTKit/QTKit.h>
#import "TCMCaptureManager.h"
#import "FSArguments.h"
#import "FSArguments_Coalescer_Internal.h"

static NSUncaughtExceptionHandler *S_defaultHandler;

static void signal_handler(int signal)
{
	[[TCMCaptureManager captureManager] teardownCaptureSession];
	exit(0);
}


static void exception_handler(NSException *anException) {
	NSLog(@"%s %@",__FUNCTION__,anException);
	S_defaultHandler(anException);
}

@interface QTCaptureDevice (SightSnapAdditions)
- (NSString *)localizedUniqueDisplayName;
@end

@implementation QTCaptureDevice (SightSnapAdditions)
- (NSString *)localizedUniqueDisplayName {
	NSString *result = [NSString stringWithFormat:@"%@ [%@ - %@]", self.localizedDisplayName, self.modelUniqueID, self.uniqueID];
	return result;
}

@end

typedef NSString * (^FSDescriptionHelper) (FSArgumentSignature *aSignature, NSUInteger aIndentLevel, NSUInteger aTerminalWidth);

@interface TCMCommandLineUtility ()
@property (nonatomic) BOOL keepRunLoopAlive;
@property (nonatomic) NSTimeInterval grabInterval;
@property (nonatomic) NSInteger frameIndex;
@property (nonatomic) NSString *baseFilePath;
@property (nonatomic, strong) NSDate *lastFrameFireDate;
@property (nonatomic, strong) NSDate *lastFrameScheduledDate;
@property (nonatomic) CGFloat fontSize;
@property (nonatomic, strong) NSString *fontName;
@property (nonatomic) BOOL shouldTimeStamp;
@property (nonatomic) NSInteger helpFirstTabPosition;
@end

@implementation TCMCommandLineUtility

+ (int)runCommandLineUtility {
	S_defaultHandler = NSGetUncaughtExceptionHandler();
	NSSetUncaughtExceptionHandler(exception_handler);
	signal(SIGINT, signal_handler);
    int result = [[TCMCommandLineUtility new] run];
    return result;
}

- (id)init {
    self = [super init];
    if (self) {
        self.grabInterval = -1.0;
        self.frameIndex = 0;
        self.fontSize = 40;
        self.fontName = @"HelveticaNeue-Bold";
        self.shouldTimeStamp = NO;
		self.helpFirstTabPosition = 30;
    }
    return self;
}

- (FSDescriptionHelper)descriptionHelperWithHelpText:(NSString *)aHelpText {
	return [self descriptionHelperWithHelpText:aHelpText valueName:nil];
}

- (FSDescriptionHelper)descriptionHelperWithHelpText:(NSString *)aHelpText valueName:(NSString *)aValueName {
	NSInteger aFirstTabPosition = self.helpFirstTabPosition;
	FSDescriptionHelper result = ^(FSArgumentSignature *aSignature, NSUInteger aIndentLevel, NSUInteger aTerminalWidth) {
		NSArray *expandedSwitches = __fsargs_expandAllSwitches(aSignature.switches);
		NSString *firstLinePrefix = [@"" stringByPaddingToLength:aIndentLevel withString:@" " startingAtIndex:0];
		NSString *followingLinesPrefix = [@"" stringByPaddingToLength:aIndentLevel + aFirstTabPosition withString:@" " startingAtIndex:0];
		NSString *argumentPart = [expandedSwitches componentsJoinedByString:@", "];
		if ([aSignature isKindOfClass:[FSValuedArgument class]]) {
			argumentPart = [@[argumentPart, [NSString stringWithFormat:@"<%@>", aValueName]] componentsJoinedByString:@" "];
		}
		argumentPart = [firstLinePrefix stringByAppendingString:argumentPart];
		NSInteger tabLength = aFirstTabPosition + aIndentLevel - argumentPart.length;
		if (tabLength > 0) {
			argumentPart = [argumentPart stringByAppendingString:[@"" stringByPaddingToLength:tabLength withString:@" " startingAtIndex:0]];
		}
		NSArray *helpTextComponents = [aHelpText componentsSeparatedByString:@"\n"];
		NSMutableString *result = [[[argumentPart stringByAppendingString:helpTextComponents[0]] stringByAppendingString:@"\n"] mutableCopy];
		for (int index=1; index < helpTextComponents.count; index++) {
			[result appendString:followingLinesPrefix];
			[result appendString:helpTextComponents[index]];
			[result appendString:@"\n"];
		}
		return result;
	};
	
	return result;
}

- (int)run {
    // Arguments setup
    FSArgumentSignature
    *list = [FSArgumentSignature argumentSignatureWithFormat:@"[-l --listDevices]"],
    *time = [FSArgumentSignature argumentSignatureWithFormat:@"[-t --time]="],
    *skipframes = [FSArgumentSignature argumentSignatureWithFormat:@"[-k --skipframes]="],
    *maxWidth = [FSArgumentSignature argumentSignatureWithFormat:@"[-x --maxwidth]="],
    *maxHeight = [FSArgumentSignature argumentSignatureWithFormat:@"[-y --maxheight]="],
    *jpegQuality = [FSArgumentSignature argumentSignatureWithFormat:@"[-j --jpegQuality]="],
    *stamp = [FSArgumentSignature argumentSignatureWithFormat:@"[-p --timeStamp]"],
    *fontName = [FSArgumentSignature argumentSignatureWithFormat:@"[-f --fontName]="],
    *fontSize = [FSArgumentSignature argumentSignatureWithFormat:@"[-s --fontSize]="],
    *device = [FSArgumentSignature argumentSignatureWithFormat:@"[-d --device]="],
    *help = [FSArgumentSignature argumentSignatureWithFormat:@"[-h --help]"];
    NSArray *signatures = @[list,device,time,skipframes,jpegQuality,maxWidth,maxHeight,stamp,fontName,fontSize,help];
	
	
	self.helpFirstTabPosition = 26;
	[list setDescriptionHelper:       [self descriptionHelperWithHelpText:@"List all available video devices and their formats."]];
	[device setDescriptionHelper:     [self descriptionHelperWithHelpText:@"Use this <device>. First partial case-insensitive\nname match is taken." valueName:@"device"]];
	[time setDescriptionHelper:       [self descriptionHelperWithHelpText:@"Takes a frame every <delay> seconds and saves it as\noutputfilename-XXXXXXX.jpg continuously." valueName:@"delay"]];
	[skipframes setDescriptionHelper: [self descriptionHelperWithHelpText:@"Skips <n> frames before taking a picture. Gives cam\nwarmup time. (default is 3, frames are @15fps)" valueName:@"n"]];
	[maxWidth  setDescriptionHelper:  [self descriptionHelperWithHelpText:@"If image is wider than <w> px, scale it down to fit." valueName:@"w"]];
	[maxHeight setDescriptionHelper:  [self descriptionHelperWithHelpText:@"If image is higher than <h> px, scale it down to fit." valueName:@"h"]];
	[jpegQuality setDescriptionHelper:[self descriptionHelperWithHelpText:@"JPEG image quality from 0.0 to 1.0 (default is 0.8)." valueName:@"q"]];
	[help setDescriptionHelper:       [self descriptionHelperWithHelpText:@"Shows this help."]];
	[stamp setDescriptionHelper:      [self descriptionHelperWithHelpText:@"Adds a Timestamp to the captured image."]];
	[fontSize setDescriptionHelper:   [self descriptionHelperWithHelpText:@"Font size for timestamp in <size> px. (default is 40)" valueName:@"size"]];
	[fontName setDescriptionHelper:   [self descriptionHelperWithHelpText:@"Postscript font name to use. Use FontBook.app->Font Info\nto find out about the available fonts on your system\n(default is 'HelveticaNeue-Bold')" valueName:@"font"]];
	
	
    FSArgumentPackage * package = [[NSProcessInfo processInfo] fsargs_parseArgumentsWithSignatures:signatures];
    NSString *outputFilename = @"sightsnap.jpg";
    if ([[package uncapturedValues] count] > 0) {
        outputFilename = [[package uncapturedValues] objectAtIndex:0];
        NSString *extension = [outputFilename pathExtension];
        if (extension.length < 3) {
            outputFilename = [outputFilename stringByAppendingPathExtension:@"jpg"];
        }
    }
    self.baseFilePath = [outputFilename stringByStandardizingPath];
	
    
	NSInteger terminalWidth = 80;
    if ([package booleanValueForSignature:help]) {
		puts("sightsnap v0.2 by @monkeydom");
        puts("usage: sightsnap [options] [output[.jpg|.png]] [options]");
		puts("");
		puts("Default output filename is signtsnap.jpg - if no extension is given, jpg is used.\nIf you add directory in front, it will be created.");
		for (FSArgumentSignature *option in signatures) {
			printf("%s",[[option descriptionForHelp:2 terminalWidth:terminalWidth] UTF8String]);
		}
		puts("");
		puts("To make timelapse videos use ffmpeg like this:\n  ffmpeg -r 15 -i 'sightsnap-\%07d.jpg' sightsnap.mp4");
    } else {
        TCMCaptureManager *captureManager = [TCMCaptureManager captureManager];
		QTCaptureDevice *defaultDevice = captureManager.defaultVideoDevice;
        if ([package booleanValueForSignature:list]) {
            puts("Video Devices:");
            for (QTCaptureDevice *device in captureManager.availableVideoDevices) {
                puts([[NSString stringWithFormat:@"%@ %@",[device isEqual:defaultDevice] ?@"*":@" ",device.localizedUniqueDisplayName] UTF8String]);
                for (QTFormatDescription *format in device.formatDescriptions) {
                    puts([[NSString stringWithFormat:@"   - %@",format.localizedFormatSummary] UTF8String]);
                }
            }
        } else {
			// ensure directory
			NSFileManager *fileManager = [NSFileManager defaultManager];
			NSString *baseDirectory = [self.baseFilePath stringByDeletingLastPathComponent];
			if (baseDirectory.length) {
				if (![fileManager fileExistsAtPath:baseDirectory isDirectory:NULL]) {
					NSError *error;
					if (![fileManager createDirectoryAtPath:baseDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
						NSLog(@"Could not create directory at %@. \n%@",baseDirectory, error);
					}
				}
				
			}

            
            QTCaptureDevice *videoDevice = defaultDevice;
            NSString *deviceString = [package firstObjectForSignature:device];
            if (deviceString) {
                NSString *searchString = deviceString.lowercaseString;
                BOOL foundDevice = NO;
                for (QTCaptureDevice *device in captureManager.availableVideoDevices) {
                    NSString *candidateString = [device.localizedUniqueDisplayName lowercaseString];
                    if ([candidateString rangeOfString:searchString].location != NSNotFound) {
                        foundDevice = YES;
                        videoDevice = device;
                        break;
                    }
                }
                if (!foundDevice) {
                    puts([[NSString stringWithFormat:@"Error: No video device matching '%@' found. Try -l for a list of available devices", deviceString] UTF8String]);
                    return -1;
                }
            }
            
            [captureManager setCurrentVideoDevice:videoDevice];
            
            id timeValue = [package firstObjectForSignature:time];
            if (timeValue) {
                self.grabInterval = [timeValue doubleValue];
            }
            
			id skipFramesValue = [package firstObjectForSignature:skipframes];
			if (skipFramesValue) {
				captureManager.skipFrames = MAX(0,[skipFramesValue integerValue]);
			}

			id maxHeightValue = [package firstObjectForSignature:maxHeight];
			if (maxHeightValue) {
				captureManager.maxHeight = MAX(0,[maxHeightValue integerValue]);
			}

			id maxWidthValue = [package firstObjectForSignature:maxWidth];
			if (maxWidthValue) {
				captureManager.maxWidth = MAX(0,[maxWidthValue integerValue]);
			} 
			
            id jpegQualityValue = [package firstObjectForSignature:jpegQuality];
            if (jpegQualityValue) {
                captureManager.jpegQuality = [jpegQualityValue doubleValue];
            }
            
            self.shouldTimeStamp = [package booleanValueForSignature:stamp];
            
            id fontNameValue = [package firstObjectForSignature:fontName];
            if (fontNameValue) {
                // test if font exists
                CGFontRef fontRef = CGFontCreateWithFontName((__bridge CFStringRef)fontNameValue);
                if (fontRef) {
                    self.fontName = fontNameValue;
                    CFRelease(fontRef);
                }
            }
            
            id fontSizeValue = [package firstObjectForSignature:fontSize];
            if (fontSizeValue) {
                self.fontSize = [fontSizeValue doubleValue];
            }
            self.lastFrameScheduledDate = [NSDate new];
			if (self.grabInterval >= 0.0 && self.grabInterval <= 2.0) {
				captureManager.shouldKeepCaptureSessionOpen = YES;
			}
            [self captureImage];
            [self startRunLoop];
        }
    }
    return 0;
}

- (NSURL *)nextFrameFileURL {
    NSURL *result;
    NSString *pathString = self.baseFilePath;
    if (self.grabInterval >= 0.0) {
        NSString *extension = [self.baseFilePath pathExtension];
        pathString = [[NSString stringWithFormat:@"%@-%07ld", [pathString stringByDeletingPathExtension], self.frameIndex] stringByAppendingPathExtension:extension];
    }
    result = [NSURL fileURLWithPath:pathString];
    return result;
}

- (void)captureImage {
    self.lastFrameFireDate = [NSDate new];

    TCMCaptureManager *captureManager = [TCMCaptureManager captureManager];
    if (self.shouldTimeStamp) {
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        NSString *dateString = [dateFormatter stringFromDate:self.lastFrameFireDate];
        CGFloat fontSize = self.fontSize;
        CGFloat fontInset = 20.0;
        
        TCMCaptureQuartzAction drawAction = ^(CGContextRef ctx, CGRect aFrame) {
            CGColorRef whiteColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
            CGColorRef blackColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.9);
            CGContextSetFillColorWithColor(ctx, whiteColor);
            CGContextSetStrokeColorWithColor(ctx, blackColor);
            CGContextSetLineWidth(ctx,fontSize/7.0);
            
            CGPoint textPoint = CGPointMake(fontInset, CGRectGetMaxY(aFrame) - fontInset - fontSize * 0.8);
            const char *text = [dateString UTF8String];
            size_t textLength = strlen(text);
    //        CGFontRef fontRef = CGFontCreateWithFontName((__bridge CFStringRef)@"HelveticaNeue-Bold");
    //        CGContextSetFontSize(ctx, 40);
    //        CGContextSetFont(ctx, fontRef);
            CGContextSelectFont(ctx, [self.fontName UTF8String], fontSize, kCGEncodingMacRoman);
            CGContextSetTextDrawingMode(ctx, kCGTextStroke);
            CGContextShowTextAtPoint(ctx, textPoint.x, textPoint.y, text, textLength);
            CGContextSetTextDrawingMode(ctx, kCGTextFill);
            CGContextShowTextAtPoint(ctx, textPoint.x, textPoint.y, text, textLength);
            
            CFRelease(whiteColor);
            CFRelease(blackColor);
    //        CFRelease(fontRef);
        };
        [captureManager setImageDrawingBlock:drawAction];
    }
    [captureManager saveFrameToURL:self.nextFrameFileURL completion:^{
        [self didCaptureImage];
    }];
}

- (void)didCaptureImage {
    self.frameIndex = self.frameIndex + 1;
    if (self.grabInterval >= 0.0) {
        self.lastFrameScheduledDate = [self.lastFrameScheduledDate dateByAddingTimeInterval:self.grabInterval];
        NSTimeInterval timeInterval = [self.lastFrameScheduledDate timeIntervalSinceNow];
        if (timeInterval < 0) timeInterval = 0.0;
        [self performSelector:@selector(captureImage) withObject:nil afterDelay:timeInterval];
    } else {
        self.keepRunLoopAlive = NO;
    }
}

- (void)startRunLoop {
    self.keepRunLoopAlive = YES;
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    while (self.keepRunLoopAlive && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

@end
