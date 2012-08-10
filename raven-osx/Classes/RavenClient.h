//
//  RavenClient.h
//  osx-applet
//
//  Created by Adam work on 8/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RavenBlock)(void);


@interface RavenClient : NSObject

@property(nonatomic, retain) NSString *uri;
@property(nonatomic, retain) NSString *publicKey;
@property(nonatomic, retain) NSString *secretKey;
@property(nonatomic, retain) NSString *projectId;


+(RavenClient *) sharedInstance;
+(RavenClient *) sharedInstance:(NSString *) dsn;

-(id) initWithDSN:(NSString *)dsn;
-(void) capture:(RavenBlock)block;
-(void) logException:(NSException *) exception;
-(void) logException:(NSException *)exception withLoggerName:(NSString *)loggerName;
-(void) installExceptionHandler;

@end
