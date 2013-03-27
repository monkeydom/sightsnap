//
//  TCMCaptureManager.m
//  sightsnap
//
//  Created by Dominik Wagner on 27.03.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "TCMCaptureManager.h"
#import <QTKit/QTKit.h>

@implementation TCMCaptureManager

+ (instancetype)captureManager {
    static dispatch_once_t predicate;
    static TCMCaptureManager *S_singleton = nil;
    dispatch_once(&predicate, ^{
        S_singleton = [TCMCaptureManager new];
    });
    return S_singleton;
}

- (NSArray *)availableVideoDevices {
    NSMutableArray *videoDevices = [NSMutableArray new];
    [videoDevices addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo]];
    [videoDevices addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed]];
    return videoDevices;
}

@end
