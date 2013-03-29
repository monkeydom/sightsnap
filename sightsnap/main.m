//
//  main.m
//  sightsnap
//
//  Created by Dominik Wagner on 27.03.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMCommandLineUtility.h"

int main(int argc, const char * argv[]) {
    int result = 0;
    @autoreleasepool {
        result = [TCMCommandLineUtility runCommandLineUtility];
    }
    return result;
}

