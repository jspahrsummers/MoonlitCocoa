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
NSString * const MLCLuaStackOverflowException = @"MLCLuaStackOverflowException";

@interface MLCState ()
@property (nonatomic, readwrite) lua_State *state;

/**
 * Attempts to ensure that \a size slots are free in the Lua stack. If not
 * enough slots are free and the stack cannot be grown, an
 * #MLCLuaStackOverflowException is thrown.
 */
- (void)growStackBySize:(int)size;
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
	[self growStackBySize:2];
	lua_getglobal(self.state, "package");
	lua_pushliteral(self.state, ";;?;?.lua;?.luac;/usr/local/lib/?.luac;/usr/local/lib/?.lua");
	lua_setfield(self.state, -2, "path");

	// initialize Metalua compiler
	[self growStackBySize:1];
	NSString *compilerPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"compiler" ofType:@"lua"];
	if (0 != luaL_dofile(self.state, [compilerPath UTF8String])) {
		NSLog(@"Could not load Metalua compiler: %s", lua_tostring(self.state, -1));
		return nil;
	}

	return self;
}

- (void)dealloc {
  	if (self.state) {
		lua_close(self.state);
		self.state = NULL;
	}
}

- (BOOL)callFunctionWithArgumentCount:(int)argCount resultCount:(int)resultCount error:(NSError **)error; {
	int ret = lua_pcall(self.state, argCount, resultCount, 0);
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

- (BOOL)loadScript:(NSString *)source error:(NSError **)error; {
  	[self growStackBySize:3];

	lua_getglobal(self.state, "compiler");
	lua_getfield(self.state, -1, "loadstring");
	lua_pushstring(self.state, [source UTF8String]);

	return [self callFunctionWithArgumentCount:1 resultCount:1 error:error];
}

- (BOOL)loadScriptAtURL:(NSURL *)URL error:(NSError **)error; {
  	NSString *source = [NSString stringWithContentsOfURL:URL usedEncoding:NULL error:error];
	if (!source)
		return NO;
	
	return [self loadScript:source error:error];
}

- (void)growStackBySize:(int)size; {
  	if (!lua_checkstack(self.state, size)) {
		[NSException raise:MLCLuaStackOverflowException format:@"Could not grow Lua stack by %i slots", size];
	}
}

@end
