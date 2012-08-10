//
//  NSString+UUID.h
//  osx-applet
//
//  Created by Adam work on 7/8/12.
//  Copyright (c) 2012 Convo Communications. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (UUID)

+ (NSString*)stringWithNewUUID;
+ (NSString *) stringWithNewHexUUID;

@end
