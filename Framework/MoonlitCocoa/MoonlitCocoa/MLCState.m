//
//  MLCState.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 24.10.11.
//  Released into the public domain.
//

#import "MLCState.h"
#import "NSDictionary+LuaAdditions.h"
#import "NSNull+LuaAdditions.h"
#import "NSNumber+LuaAdditions.h"
#import "NSString+LuaAdditions.h"
#import <lauxlib.h>
#import <lualib.h>

NSString * const MLCLuaErrorDomain = @"MLCLuaErrorDomain";
NSString * const MLCLuaStackOverflowException = @"MLCLuaStackOverflowException";

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
	[self growStackBySize:2];
	[self enforceStackDelta:0 forBlock:^{
		[self pushGlobal:@"package"];

		lua_pushliteral(self.state, ";;?;?.lua;?.luac;/usr/local/lib/?.luac;/usr/local/lib/?.lua");
		lua_setfield(self.state, -2, "path");
		lua_pop(self.state, 1);
		return YES;
	}];

	// initialize Metalua compiler
	BOOL result = [self enforceStackDelta:0 forBlock:^{
		NSString *compilerPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"compiler" ofType:@"lua"];
		if (0 != luaL_dofile(self.state, [compilerPath UTF8String])) {
			NSLog(@"Could not load Metalua compiler: %@", [NSString popFromStack:self]);
			return NO;
		}

		return YES;
	}];

	if (!result)
		return nil;
	else
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
			NSString *message = [NSString popFromStack:self];
			if (message) {
				userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
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

- (id)getValueOnStack; {
  	[self growStackBySize:1];

	// duplicate the value at the top of the stack, so that we can pop and then
	// leave the stack in its previous state
  	lua_pushvalue(self.state, -1);

	return [self popValueOnStack];
}

- (BOOL)loadScript:(NSString *)source error:(NSError **)error; {
	source = [@"require 'metalua.runtime'\n\n" stringByAppendingString:source];
  
  	[self growStackBySize:2];

	return [self enforceStackDelta:1 forBlock:^{
		[self pushGlobal:@"compiler"];
		[self popTableAndPushField:@"loadstring"];

		[source pushOntoStack:self];

		// on the stack should be:
		// { compiler.loadstring, source }
		return [self callFunctionWithArgumentCount:1 resultCount:1 error:error];
	}];
}

- (BOOL)loadScriptAtURL:(NSURL *)URL error:(NSError **)error; {
  	NSString *source = [NSString stringWithContentsOfURL:URL usedEncoding:NULL error:error];
	if (!source)
		return NO;
	
	return [self loadScript:source error:error];
}

- (BOOL)enforceStackDelta:(int)delta forBlock:(BOOL (^)(void))block; {
  	int top = lua_gettop(self.state);
	BOOL result = block();
	int newTop = lua_gettop(self.state);

	NSAssert2(newTop == top + delta, @"Actual stack delta (%i) does not match expected delta (%i)", newTop - top, delta);

	return result;
}

- (void)growStackBySize:(int)size; {
  	if (!lua_checkstack(self.state, size)) {
		[NSException raise:MLCLuaStackOverflowException format:@"Could not grow Lua stack by %i slots", size];
	}
}

- (void)popTableAndPushField:(NSString *)field; {
  	lua_getfield(self.state, -1, [field UTF8String]);

	// replace the original table in the stack
	lua_replace(self.state, -2);
}

- (id)popValueOnStack; {
	switch (lua_type(self.state, -1)) {
	case LUA_TNIL:
		return [NSNull popFromStack:self];

	case LUA_TNUMBER:
	case LUA_TBOOLEAN:
		return [NSNumber popFromStack:self];

	case LUA_TSTRING:
		return [NSString popFromStack:self];

	case LUA_TTABLE:
		return [NSDictionary popFromStack:self];

	case LUA_TLIGHTUSERDATA:
		return (__bridge id)lua_touserdata(self.state, -1);

	case LUA_TTHREAD:
		// TODO: not yet implemented
		//return [MLCState ...
		return nil;
	
	case LUA_TFUNCTION:
	case LUA_TUSERDATA:
	default:
		return nil;
	}
}

- (void)pushGlobal:(NSString *)symbol; {
	lua_getglobal(self.state, [symbol UTF8String]);
}

@end
