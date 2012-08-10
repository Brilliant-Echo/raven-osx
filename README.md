raven-osx is a sentry[http://www.getsentry.com] client for OSX.

Installation
============
*(Modified from json-framework instructions)*

Installing raven-osx is a simple process of copying the raven-osx source files
into your own Xcode project.

1. In the Finder, navigate to the distribution's folder
1. Navigate into the `Classes` folder.
1. Select all the files and drag-and-drop them into your Xcode project.
1. Tick the **Copy items into destination group's folder** option.
1. Use `#import "RavenClient.h"` in  your source files.

Integration
============

The first thing you **MUST** do in order to use raven-osx is to initialize
a client with a Sentry DSN. raven-osx comes with a shared instance for use in your
application but can also be instantiated individually.

	RavenClient *raven = [RavenClient sharedInstance:@"https://public:secret@example.com/sentry/default"];

OR

	RavenClient *raven = [[RavenClient alloc] initWithDSN:@"https://public:secret@example.com/sentry/default"];

Depending on the level of error collection you want in your application
there are several complementary ways to integrate raven-osx into your
project.

First you can simply capture exceptions that occur in specific areas of
code using the block capture syntax

	[[RavenClient sharedInstance] capture:^{
	    /* your code goes here! */
	}];

You can also edit your `Info.plist` file and set the value of `NSPrincipalClass` 
to `RavenApplication.` This will make your application run with a main
Application class that implements an exception handler that logs to Sentry.

Finally, you can also install an uncaught exception handler and signal handlers
to catch any crashes that occur in your application. The best way to do this is in
your `applicationDidFinishLaunching` method. Simply call

	[[RavenClient sharedInstance] performSelector:@selector(installExceptionHandler) withObject:nil afterDelay:0];
	
The reason for the delay and limitations in this technique can be read about 
[here](http://cocoawithlove.com/2010/05/handling-unhandled-exceptions-and.html)

