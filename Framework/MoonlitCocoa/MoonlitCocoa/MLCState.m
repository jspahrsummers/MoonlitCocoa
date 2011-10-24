//
//  MLCState.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 24.10.11.
//  Released into the public domain.
//

#import "MLCState.h"
#import <lauxlib.h>
#import <lualib.h>

NSString * const MLCLuaErrorDomain = @"MLCLuaErrorDomain";

@interface MLCState ()
@property (nonatomic, readwrite) lua_State *state;
@end

@implementation MLCState
@synthesize state = m_state;

+ (id)state; {
	return [[self alloc] init];
}

- (id)init; {
  	self = [super init];
	if (!self)
		return nil;
	
	self.state = luaL_newstate();
	luaL_openlibs(self.state);

	// add additional package paths (including the path used by Homebrew)
	lua_getglobal(self.state, "package");
	lua_pushliteral(self.state, ";;?;?.lua;?.luac;/usr/local/lib/?.luac;/usr/local/lib/?.lua");
	lua_setfield(self.state, -2, "path");

	return self;
}

- (void)dealloc {
  	if (self.state) {
		lua_close(self.state);
		self.state = NULL;
	}
}

- (BOOL)loadScript:(NSString *)source error:(NSError **)error; {
	lua_getglobal(self.state, "compiler");
	lua_getfield(self.state, -1, "loadstring");
	lua_pushstring(self.state, [source UTF8String]);

	int ret = lua_pcall(self.state, 1, 1, 0);
	if (ret == 0) {
		return YES;
	} else {
		if (error) {
			NSDictionary *userInfo = nil;
			const char *msg = lua_tostring(self.state, -1);
			if (msg) {
				userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:msg] forKey:NSLocalizedDescriptionKey];
			}

			*error = [NSError
				errorWithDomain:MLCLuaErrorDomain
				code:ret
				userInfo:userInfo
			];
		}

		return NO;
	}
}

- (BOOL)loadScriptAtURL:(NSURL *)URL error:(NSError **)error; {
  	NSString *source = [NSString stringWithContentsOfURL:URL usedEncoding:NULL error:error];
	if (!source)
		return NO;
	
	return [self loadScript:source error:error];
}

@end
