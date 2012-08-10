//
//  NSObject+JSONData.m
//  raven-osx
//
//  Created by Adam work on 8/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSObject+JSONData.h"
#import "SBJson.h"

@implementation NSObject (JSONData)

-(NSData *) jsonData {
    NSString *json = [self JSONRepresentation];
    return [NSData dataWithBytes:[json UTF8String] length:[json length]];
}

@end
