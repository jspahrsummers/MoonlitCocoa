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

	NSString *compilerPath = [[NSBundle mainBundle] pathForResource:@"compiler" ofType:@"lua"];
	if (0 != luaL_dofile(state.state, [compilerPath UTF8String])) {
		NSLog(@"Could not load Metalua compiler: %s", lua_tostring(state.state, -1));
	}

	NSURL *helloURL = [[NSBundle mainBundle] URLForResource:@"hello" withExtension:@"lua"];
	NSError *error = nil;
	if (![state loadScriptAtURL:helloURL error:&error]) {
		NSLog(@"Error loading hello.lua: %@", error);
	} else {
		lua_pcall(state.state, 0, 0, 0);
	}
}

@end
