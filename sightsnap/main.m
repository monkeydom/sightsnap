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
        NSLog(@"%s snapsnap %@",__FUNCTION__,[[NSProcessInfo processInfo] arguments]);
        // Arguments setup
        FSArgumentSignature
        *list = [FSArgumentSignature argumentSignatureWithFormat:@"[-l --listDevices]"],
        *help = [FSArgumentSignature argumentSignatureWithFormat:@"[-h --help]"];
                        
        NSArray * signatures = @[list];
        FSArgumentPackage * package = [[NSProcessInfo processInfo] fsargs_parseArgumentsWithSignatures:signatures];

        TCMCaptureManager *captureManager = [TCMCaptureManager captureManager];
        if ([package booleanValueForSignature:list]) {
            puts([[NSString stringWithFormat:@"Video Devices:\n%@",captureManager.availableVideoDevices] UTF8String]);
        }
        if ([package booleanValueForSignature:help]) {
            NSLog(@"%s HEEEELP",__FUNCTION__);
        }
        
    }
    return 0;
}

