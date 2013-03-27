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

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        TCMCaptureManager *captureManager = [TCMCaptureManager captureManager];
        NSLog(@"Video Devices:\n%@",captureManager.availableVideoDevices);
    }
    return 0;
}

