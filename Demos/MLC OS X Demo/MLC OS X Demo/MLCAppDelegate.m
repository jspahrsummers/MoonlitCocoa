//
//  MLCAppDelegate.m
//  MLC OS X Demo
//
//  Created by Justin Spahr-Summers on 24.10.11.
//  Released into the public domain.
//

#import "MLCAppDelegate.h"
#import <lua.h>
#import <lauxlib.h>
#import <lualib.h>

@implementation MLCAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	lua_State *state = luaL_newstate();
	luaL_openlibs(state);

	NSString *helloPath = [[NSBundle mainBundle] pathForResource:@"hello" ofType:@"lua"];
	luaL_dofile(state, [helloPath UTF8String]);

	lua_close(state);
}

@end
