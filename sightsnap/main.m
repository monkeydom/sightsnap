//
//  main.m
//  sightsnap
//
//  Created by Dominik Wagner on 27.03.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        
        NSMutableArray *videoDevices = [NSMutableArray new];
        [videoDevices addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo]];
        [videoDevices addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed]];
        
        NSLog(@"Video Devices:\n%@",videoDevices);
    }
    return 0;
}

