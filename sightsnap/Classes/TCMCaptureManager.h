//
//  TCMCaptureManager.h
//  sightsnap
//
//  Created by Dominik Wagner on 27.03.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCMCaptureManager : NSObject
+ (instancetype)captureManager;

- (NSArray *)availableVideoDevices;
@end
