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

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Arguments setup
        FSArgumentSignature
        *list = [FSArgumentSignature argumentSignatureWithFormat:@"[-l --listDevices]"],
        *device = [FSArgumentSignature argumentSignatureWithFormat:@"[-d --device]="],
        *help = [FSArgumentSignature argumentSignatureWithFormat:@"[-h --help]"];
        NSArray * signatures = @[list,device, help];
        FSArgumentPackage * package = [[NSProcessInfo processInfo] fsargs_parseArgumentsWithSignatures:signatures];

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
                // snap snap
                QTCaptureSession *session = [[QTCaptureSession alloc] init];
                
            }
        }
        
    }
    return 0;
}

