//
//  FSSwitchToken.h
//  ArgumentParser
//
//  Created by Christopher Miller on 5/17/12.
//  Copyright (c) 2012 FSDEV. All rights reserved.
//

#import "CPToken.h"

@interface FSSwitchToken : CPToken
@property (strong) NSString * identifier;
+ (id)switchTokenWithIdentifier:(NSString *)identifier;
- (id)initWithIdentifier:(NSString *)identifier;
@end
