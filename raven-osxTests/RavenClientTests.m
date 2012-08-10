//
//  RavenClientTests.m
//  osx-applet
//
//  Created by Adam work on 8/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RavenClientTests.h"
#import "RavenClient.h"

@interface RavenClientTests () {
    RavenClient *_client;
}

@end

@implementation RavenClientTests

-(void) setUp {
}

-(void) testParseDSN {
    NSArray *equivalentDSNs = [NSArray arrayWithObjects:@"https://5f31dba71ab64ff4aaa3dcf4042e2238:792b7af4b03047c6829e2f09633c5e30@app.getsentry.com/test/1180", @"gevent+https://5f31dba71ab64ff4aaa3dcf4042e2238:792b7af4b03047c6829e2f09633c5e30@app.getsentry.com/test/1180", @"gevent+threaded+https://5f31dba71ab64ff4aaa3dcf4042e2238:792b7af4b03047c6829e2f09633c5e30@app.getsentry.com/test/1180", nil];
    
    for (NSString *dsn in equivalentDSNs) {
        RavenClient *c = [[RavenClient alloc] initWithDSN:dsn];
        STAssertEqualObjects(@"https://app.getsentry.com/test", c.uri, @"URI parsed incorrectly");
        STAssertEqualObjects(@"5f31dba71ab64ff4aaa3dcf4042e2238", c.publicKey, @"public key parsed incorrectly");
        STAssertEqualObjects(@"792b7af4b03047c6829e2f09633c5e30", c.secretKey, @"secret key parsed incorrectly");
        STAssertEqualObjects(@"1180", c.projectId, @"projectId parsed incorrectly");
        
        [c release];
    }    
}

@end
