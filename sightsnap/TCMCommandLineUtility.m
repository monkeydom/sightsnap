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

@interface TCMCommandLineUtility ()
@property (nonatomic) BOOL keepRunLoopAlive;
@property (nonatomic) NSTimeInterval grabInterval;
@property (nonatomic) NSInteger frameIndex;
@property (nonatomic) NSString *baseFilePath;
@property (nonatomic, strong) NSDate *lastFrameFireDate;
@end

@implementation TCMCommandLineUtility

+ (int)runCommandLineUtility {
    int result = [[TCMCommandLineUtility new] run];
    return result;
}

- (id)init {
    self = [super init];
    if (self) {
        self.grabInterval = -1.0;
        self.frameIndex = 0;
    }
    return self;
}

- (int)run {
    // Arguments setup
    FSArgumentSignature
    *list = [FSArgumentSignature argumentSignatureWithFormat:@"[-l --listDevices]"],
    *time = [FSArgumentSignature argumentSignatureWithFormat:@"[-t --time]="],
    *device = [FSArgumentSignature argumentSignatureWithFormat:@"[-d --device]="],
    *help = [FSArgumentSignature argumentSignatureWithFormat:@"[-h --help]"];
    NSArray * signatures = @[list,device,time,help];
    FSArgumentPackage * package = [[NSProcessInfo processInfo] fsargs_parseArgumentsWithSignatures:signatures];
    NSString *outputFilename = @"sightsnap.jpg";
    if ([[package uncapturedValues] count] > 0) {
        outputFilename = [[package uncapturedValues] objectAtIndex:0];
    }
    self.baseFilePath = [outputFilename stringByStandardizingPath];
    
    if ([package booleanValueForSignature:help]) {
        printf("sightsnap\n\n");
        printf("%s", [[list descriptionForHelp:2 terminalWidth:80] UTF8String]);
        printf("%s", [[device descriptionForHelp:2 terminalWidth:80] UTF8String]);
        printf("%s", [[time descriptionForHelp:2 terminalWidth:80] UTF8String]);
        printf("%s", [[help descriptionForHelp:2 terminalWidth:80] UTF8String]);
        printf("\n");
        printf("created by @monkeydom\n");
    } else {
        TCMCaptureManager *captureManager = [TCMCaptureManager captureManager];
        if ([package booleanValueForSignature:list]) {
            puts([[NSString stringWithFormat:@"Video Devices:\n%@",[[captureManager.availableVideoDevices valueForKeyPath:@"localizedDisplayName"] componentsJoinedByString:@"\n"]] UTF8String]);
        } else {
            
            QTCaptureDevice *videoDevice = [captureManager.availableVideoDevices lastObject];
            NSString *deviceString = [package firstObjectForSignature:device];
            if (deviceString) {
                NSString *searchString = deviceString.lowercaseString;
                BOOL foundDevice = NO;
                for (QTCaptureDevice *device in captureManager.availableVideoDevices) {
                    NSString *candidateString = [device.localizedDisplayName lowercaseString];
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
        pathString = [[NSString stringWithFormat:@"%@-%05ld", [pathString stringByDeletingPathExtension], self.frameIndex] stringByAppendingPathExtension:extension];
    }
    result = [NSURL fileURLWithPath:pathString];
    return result;
}

- (void)captureImage {
    self.lastFrameFireDate = [NSDate new];
    [[TCMCaptureManager captureManager] saveFrameToURL:self.nextFrameFileURL completion:^{
        [self didCaptureImage];
    }];
}

- (void)didCaptureImage {
    self.frameIndex = self.frameIndex + 1;
    if (self.grabInterval >= 0.0) {
        NSTimeInterval timeInterval = [[self.lastFrameFireDate dateByAddingTimeInterval:self.grabInterval] timeIntervalSinceNow];
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
