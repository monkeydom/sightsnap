//
//  NSArray+Functional.m
//  CoreParse
//
//  Created by Tom Davie on 20/08/2012.
//  Copyright (c) 2012 In The Beginning... All rights reserved.
//

#import "NSArray+Functional.h"

@implementation NSArray (Functional)

- (NSArray *)map:(id(^)(id obj))block
{
    NSUInteger c = [self count];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:c];
    
    NSUInteger nonNilCount = 0;
    for (id obj in self)
    {
        id r = block(obj);
        if (nil != r)
        {
            [result addObject:r];
            nonNilCount++;
        }
    }
    
    return result;
}

@end
