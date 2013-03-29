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
@end

@implementation TCMCommandLineUtility

+ (int)runCommandLineUtility {
    int result = [[TCMCommandLineUtility new] run];
    return result;
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
            [captureManager saveFrameToURL:[NSURL fileURLWithPath:outputFilename] completion:^{
                [self didCaptureImage];
            }];

            [self startRunLoop];
        }
    }
    return 0;
}

- (void)didCaptureImage {
    self.keepRunLoopAlive = NO;
}

- (void)startRunLoop {
    self.keepRunLoopAlive = YES;
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    while (self.keepRunLoopAlive && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

@end
