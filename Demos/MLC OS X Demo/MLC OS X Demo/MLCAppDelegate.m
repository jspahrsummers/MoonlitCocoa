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

	lua_getglobal(state, "package");
	lua_pushliteral(state, "?;?.lua;?.luac;/usr/local/lib/?.luac;/usr/local/lib/?.lua");
	lua_setfield(state, -2, "path");

	NSString *compilerPath = [[NSBundle mainBundle] pathForResource:@"compiler" ofType:@"lua"];
	if (0 != luaL_dofile(state, [compilerPath UTF8String])) {
		NSLog(@"Could not load Metalua compiler: %s", lua_tostring(state, -1));
	}

	NSString *helloPath = [[NSBundle mainBundle] pathForResource:@"hello" ofType:@"lua"];
	
	lua_getglobal(state, "compiler");
	lua_getfield(state, -1, "loadfile");
	lua_pushstring(state, [helloPath UTF8String]);

	lua_pcall(state, 1, 1, 0);
	NSLog(@"top of stack: %s", lua_tostring(state, -1));

	lua_pcall(state, 0, 0, 0);

	lua_close(state);
}

@end
