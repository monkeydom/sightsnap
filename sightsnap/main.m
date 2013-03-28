//
//  main.m
//  sightsnap
//
//  Created by Dominik Wagner on 27.03.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>
#import "TCMCaptureManager.h"
#import "FSArguments.h"

static BOOL shouldKeepRunning = YES;

void TCMCauseRunLoopToStop() {
    shouldKeepRunning = NO;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Arguments setup
        FSArgumentSignature
        *list = [FSArgumentSignature argumentSignatureWithFormat:@"[-l --listDevices]"],
        *device = [FSArgumentSignature argumentSignatureWithFormat:@"[-d --device]="],
        *help = [FSArgumentSignature argumentSignatureWithFormat:@"[-h --help]"];
        NSArray * signatures = @[list,device, help];
        FSArgumentPackage * package = [[NSProcessInfo processInfo] fsargs_parseArgumentsWithSignatures:signatures];
        NSString *outputFilename = @"sightsnap.jpg";
        if ([[package uncapturedValues] count] > 0) {
            outputFilename = [[package uncapturedValues] objectAtIndex:0];
        }
        if ([package booleanValueForSignature:help]) {
            printf("sightsnap\n\n");
            printf("%s", [[list descriptionForHelp:2 terminalWidth:80] UTF8String]);
            printf("%s", [[device descriptionForHelp:2 terminalWidth:80] UTF8String]);
            printf("%s", [[help descriptionForHelp:2 terminalWidth:80] UTF8String]);
            printf("\n");
            printf("created by @monkeydom\n");
        } else {
            TCMCaptureManager *captureManager = [TCMCaptureManager captureManager];
            if ([package booleanValueForSignature:list]) {
                puts([[NSString stringWithFormat:@"Video Devices:\n%@",[captureManager.availableVideoDevices componentsJoinedByString:@"\n"]] UTF8String]);
            } else {
                QTCaptureDevice *videoDevice = [captureManager.availableVideoDevices lastObject];
                [captureManager setCurrentVideoDevice:videoDevice];
                [captureManager saveFrameToURL:[NSURL fileURLWithPath:outputFilename]];
            }
 
            NSRunLoop *theRL = [NSRunLoop currentRunLoop];
            while (shouldKeepRunning && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
        }
        
    }
    return 0;
}

