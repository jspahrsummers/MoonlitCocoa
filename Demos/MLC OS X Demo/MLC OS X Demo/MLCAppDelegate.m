//
//  MLCAppDelegate.m
//  MLC OS X Demo
//
//  Created by Justin Spahr-Summers on 24.10.11.
//  Released into the public domain.
//

#import "MLCAppDelegate.h"
#import <MoonlitCocoa/MoonlitCocoa.h>
#import <lua.h>
#import <lauxlib.h>
#import <lualib.h>

@implementation MLCAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	MLCState *state = [MLCState state];

	NSURL *helloURL = [[NSBundle mainBundle] URLForResource:@"hello" withExtension:@"lua"];
	NSError *error = nil;
	if (![state loadScriptAtURL:helloURL error:&error]) {
		NSLog(@"Error loading hello.lua: %@", error);
		return;
	}

	if (![state callFunctionWithArgumentCount:0 resultCount:0 error:&error]) {
		NSLog(@"Error running hello.lua: %@", error);
		return;
	}
}

@end
