//
//  RavenClient.m
//  osx-applet
//
//  Created by Adam work on 8/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RavenClient.h"

#import <CommonCrypto/CommonHMAC.h>
#import <ExceptionHandling/NSExceptionHandler.h>
#import <execinfo.h>

#import "NSString+UUID.h"
#import "NSObject+JSONData.h"

void HandleException(NSException *exception);
void SignalHandler(int signal);

RavenClient *__gRavenClientInstance;

@interface RavenClient ()
@property(nonatomic, retain) NSURL *dsn;

@end

@implementation RavenClient

@synthesize uri=_uri, publicKey=_publicKey, secretKey=_secretKey, projectId=_projectId, dsn=_dsn;

+(RavenClient *) sharedInstance {
    @synchronized(self)
    {
        if (__gRavenClientInstance == nil) {
            [NSException raise:@"Raven client not initialized" format:@"Raven client not initialized. use sharedInstance:(NSString *) dsn"];
        }
    }
    return(__gRavenClientInstance);
}

+(RavenClient *) sharedInstance:(NSString *) dsn {

    @synchronized(self)
    {
        if (__gRavenClientInstance == nil)
            __gRavenClientInstance = [[self alloc] initWithDSN:dsn];
    }

    return(__gRavenClientInstance);
}

-(NSString *) version {
    return [NSString stringWithString:@"0.1"];
}

-(id) initWithDSN:(NSString *)dsn {
    self = [super init];
    if (self != nil) {
        
        // ignore transport options
        NSRange endRange = [dsn rangeOfString:@"://"];
        if (endRange.location == NSNotFound) {
            [NSException raise:@"Invalid DSN" format:@"Invalid DSN string: %@", dsn];
        }
        endRange = NSMakeRange(0, endRange.location);
        
        NSRange plusRange = [dsn rangeOfString:@"+" options:0 range:endRange];
        while (plusRange.location != NSNotFound) {
            dsn = [dsn substringFromIndex:plusRange.location + 1];
            endRange.length -= plusRange.location + 1;
            plusRange = [dsn rangeOfString:@"+" options:0 range:endRange];
        } 
        
        self.dsn = [NSURL URLWithString:dsn];
        self.publicKey = self.dsn.user;
        self.secretKey = self.dsn.password;
        self.projectId = self.dsn.lastPathComponent;
        self.uri = [NSString stringWithFormat:@"%@://%@/%@", self.dsn.scheme, self.dsn.host, [[self.dsn.pathComponents subarrayWithRange:NSMakeRange(1, self.dsn.pathComponents.count - 2)] componentsJoinedByString:@"/"]];
    }
    
    return self;
}

-(void) capture:(RavenBlock)block {
    [self capture:block withLoggerName:nil];
}

-(void) capture:(RavenBlock)block withLoggerName:(NSString *)loggerName {
    @try {
        block();
    }
    @catch (NSException *e) {
        [self logException:e withLoggerName:loggerName];
        @throw e;
    }
}

-(void) logException:(NSException *)exception {
    [self logException:exception withLoggerName:nil];
}

-(NSDictionary *) tagsFor:(NSException *) exception {
    return [NSDictionary dictionaryWithObjectsAndKeys:[[NSProcessInfo processInfo] operatingSystemVersionString], @"os-version", nil];
}

-(NSString *) sentryVersion {
    return [NSString stringWithString:@"2.0"];
}

-(NSString *) sentryClient {
    return [NSString stringWithFormat:@"raven-osx/%@", [self version]];
}

- (NSString*)base64forData:(NSData*)theData {
    
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}


-(NSString *) generateSignature:(NSData *)json withTime:(NSDate *)date {
    NSString *jsonString = [[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding] autorelease];
    NSString *data = [NSString stringWithFormat:@"%0.0f %@", [date timeIntervalSince1970], jsonString];
    
    const char *cKey  = [self.secretKey cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[[NSData alloc] initWithBytes:cHMAC
                                          length:sizeof(cHMAC)] autorelease];
    
    return [self base64forData:HMAC];
}

-(NSString *) sentryAuthHeader:(NSData *)json {
    NSDate *now = [NSDate date];
//    return [NSString stringWithFormat:@"Sentry sentry_version=%@, sentry_client=%@, sentry_timestamp=%0.0f, sentry_key=%@, sentry_signature=%@", [self sentryVersion], [self sentryClient], [now timeIntervalSince1970], self.publicKey, [self generateSignature:json withTime:now]];
    return [NSString stringWithFormat:@"Sentry sentry_version=%@, sentry_client=%@, sentry_timestamp=%0.0f, sentry_key=%@", [self sentryVersion], [self sentryClient], [now timeIntervalSince1970], self.publicKey];
}

-(NSDictionary *) exceptionInfo:(NSException *) exception withLoggerName:(NSString *)loggerName {
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    
    NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    [dateFormatter setCalendar:calendar];
    
    NSLocale *locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
    [dateFormatter setLocale:locale];
    
    NSTimeZone *timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    [dateFormatter setTimeZone:timeZone];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    NSString *nowString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSMutableDictionary *exceptionInfo = [NSMutableDictionary dictionary];
    [exceptionInfo setObject:self.projectId forKey:@"project"];
    [exceptionInfo setObject:[NSString stringWithNewHexUUID] forKey:@"event_id"];
    [exceptionInfo setObject:[NSString stringWithFormat:@"%@: %@", exception.name, exception.reason] forKey:@"message"];
    [exceptionInfo setObject:nowString forKey:@"timestamp"];
    [exceptionInfo setObject:@"error" forKey:@"level"];
    [exceptionInfo setObject:[self tagsFor:exception] forKey:@"tags"];
    
    if (loggerName != nil) {
        [exceptionInfo setObject:loggerName forKey:@"logger"];
    }
    else {
        [exceptionInfo setObject:@"default" forKey:@"logger"];
    }
    
    NSArray *backTraceSymbols = [exception callStackSymbols];

    // stack trace
    if (backTraceSymbols && backTraceSymbols.count > 0) {
        NSMutableArray *frames = [NSMutableArray array];
        for (NSString *symbol in backTraceSymbols) {
            [frames addObject:[NSDictionary dictionaryWithObjectsAndKeys:symbol, @"filename", [NSNumber numberWithInt:0], @"lineno", nil]];
        }
        [exceptionInfo setObject:[NSDictionary dictionaryWithObject:frames forKey:@"frames"] forKey:@"sentry.interfaces.Stacktrace"];

        // culprit
        [exceptionInfo setObject:[[backTraceSymbols objectAtIndex:0] description] forKey:@"culprit"];
    }
    
    // extra
    if (exception.userInfo != nil) {
        NSMutableDictionary *readableUserInfo = [NSMutableDictionary dictionaryWithCapacity:exception.userInfo.count];
        for (NSObject *k in exception.userInfo.allKeys) {
            [readableUserInfo setObject:[[exception.userInfo objectForKey:k] description] forKey:[k description]];
        }
        [exceptionInfo  setObject:[NSDictionary dictionaryWithObjectsAndKeys:readableUserInfo, @"userInfo", nil] forKey:@"extra"];
    }

    return [NSDictionary dictionaryWithDictionary:exceptionInfo];
}

-(void) logException:(NSException *)exception withLoggerName:(NSString *)loggerName {
    @autoreleasepool {
        NSDictionary *exceptionInfo = [self exceptionInfo:exception withLoggerName:loggerName];
        
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@api/store/", self.uri]]];
        [urlRequest setHTTPMethod:@"POST"];
        
        NSData *json = [exceptionInfo jsonData];
        [urlRequest setValue:[self sentryAuthHeader:json] forHTTPHeaderField:@"X-Sentry-Auth"];
        [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [urlRequest setHTTPBody:json];
        
        NSURLResponse *response = nil;
        NSError *error = nil;
        
        NSData *responseData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
        if (error != nil) {
            NSLog(@"Failed to send sentry event: %@", error);
        }
        else {
            NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *) response;
            if (200 != [urlResponse statusCode]) {
                NSLog(@"Error posting to sentry (status code: %lu) -- headers:%@, body:%@", [urlResponse statusCode], [urlResponse allHeaderFields], (NSString *)[[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
            }
        }        
    }
}

-(void) installExceptionHandler {
    NSSetUncaughtExceptionHandler(&HandleException);
    signal(SIGABRT, SignalHandler);
    signal(SIGILL, SignalHandler);
    signal(SIGSEGV, SignalHandler);
    signal(SIGFPE, SignalHandler);
    signal(SIGBUS, SignalHandler);
}

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldLogException:(NSException *)exception mask:(unsigned int)aMask {
    return YES;
}
@end

void HandleException(NSException *exception)
{
    [[RavenClient sharedInstance] logException:exception];
    [exception raise];
}

int __gSignalCount = 0;
void SignalHandler(int sig)
{    
    if (__gSignalCount++ < 3) {
        void* callstack[128];
        int frames = backtrace(callstack, 128);
        char **strs = backtrace_symbols(callstack, frames);
        
        int i;
        NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
        for (i = 4; i < 9; i++) {
            [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
        }
        free(strs);

        [[RavenClient sharedInstance] logException:[NSException exceptionWithName:@"SignalException" reason: [NSString stringWithFormat: NSLocalizedString(@"Signal %d was raised.", nil), sig] userInfo: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:sig], @"signal", backtrace, @"backtrace", nil]]];        
    }
    
    signal(sig, SIG_DFL);
    raise(sig);
}

