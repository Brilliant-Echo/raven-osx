//
//  RavenApplication.m
//  osx-applet
//
//  Created by Adam work on 8/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RavenApplication.h"
#import "RavenClient.h"

@implementation RavenApplication

-(void)reportException:(NSException *)theException {
    [[RavenClient sharedInstance] logException:theException];
}

@end
