//
//  NSString+UUID.m
//  osx-applet
//
//  Created by Adam work on 7/8/12.
//  Copyright (c) 2012 Convo Communications. All rights reserved.
//

#import "NSString+UUID.h"

@implementation NSString (UUID)

+ (NSString*)stringWithNewUUID
{
    // Create a new UUID
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    
    // Get the string representation of the UUID
    NSString *newUUID = (__bridge_transfer NSString*)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    return [newUUID autorelease];
}

+ (NSString *) stringWithNewHexUUID {
    // Create a new UUID
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    
    // Get the string representation of the UUID
    CFUUIDBytes bytes = CFUUIDGetUUIDBytes(uuidObj);
    const unsigned char *dataBuffer = (const unsigned char *)&bytes;
    
    if (!dataBuffer)
        return [NSString string];
    
    NSUInteger          dataLength  = sizeof(bytes);
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02x", (unsigned long)dataBuffer[i]]];
    
    CFRelease(uuidObj);
    return [NSString stringWithString:hexString];
}

@end
