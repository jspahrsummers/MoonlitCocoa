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

/**
 * Reserves at least \a size slots in the stack and executes \a block. When
 * \a block is done executing, pops stack values as necessary to restore it
 * to the original size.
 *
 * Returns the value returned by \a block.
 *
 * @warning This method should not be used if a value is meant to be left on the
 * stack, as it would be popped off.
 */
- (BOOL)growStackBySize:(int)size forBalancedBlock:(BOOL (^)(void))block;
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
	[self growStackBySize:2 forBalancedBlock:^{
		[self pushGlobal:@"package"];

		lua_pushliteral(self.state, ";;?;?.lua;?.luac;/usr/local/lib/?.luac;/usr/local/lib/?.lua");
		lua_setfield(self.state, -2, "path");
		return YES;
	}];

	// initialize Metalua compiler
	BOOL result = [self growStackBySize:1 forBalancedBlock:^{
		NSString *compilerPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"compiler" ofType:@"lua"];
		if (0 != luaL_dofile(self.state, [compilerPath UTF8String])) {
			NSLog(@"Could not load Metalua compiler: %@", [self popString]);
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
			NSString *message = [self popString];
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

- (BOOL)loadScript:(NSString *)source error:(NSError **)error; {
  	[self growStackBySize:2];

	[self pushGlobal:@"compiler"];
	lua_getfield(self.state, -1, "loadstring");

	// replace 'compiler' table with the loadstring function to shrink the stack
	// by 1
	lua_replace(self.state, -2);

	[self pushString:source];

	// on the stack should be:
	// { compiler.loadstring, source }
	return [self callFunctionWithArgumentCount:1 resultCount:1 error:error];
}

- (BOOL)loadScriptAtURL:(NSURL *)URL error:(NSError **)error; {
  	NSString *source = [NSString stringWithContentsOfURL:URL usedEncoding:NULL error:error];
	if (!source)
		return NO;
	
	return [self loadScript:source error:error];
}

- (BOOL)growStackBySize:(int)size forBalancedBlock:(BOOL (^)(void))block; {
  	int top = lua_gettop(self.state);
  	[self growStackBySize:size];

	BOOL result = block();
	int newTop = lua_gettop(self.state);

	NSAssert(newTop >= top, @"Stack should not be smaller than its original size after executing some balanced operations");
	if (newTop > top) {
		lua_pop(self.state, newTop - top);
	}

	return result;
}

- (void)growStackBySize:(int)size; {
  	if (!lua_checkstack(self.state, size)) {
		[NSException raise:MLCLuaStackOverflowException format:@"Could not grow Lua stack by %i slots", size];
	}
}

- (NSString *)popString; {
  	size_t len = 0;
	const char *cStr = lua_tolstring(self.state, -1, &len);
	if (!cStr)
		return nil;
	
	lua_pop(self.state, 1);
	
	return [[NSString alloc] initWithBytes:cStr length:len encoding:NSUTF8StringEncoding];
}

- (void)pushGlobal:(NSString *)symbol; {
	lua_getglobal(self.state, [symbol UTF8String]);
}

- (void)pushString:(NSString *)str; {
  	NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
	lua_pushlstring(self.state, [data bytes], [data length]);
}

@end
