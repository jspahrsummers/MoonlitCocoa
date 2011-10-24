//
//  MLCLuaState.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 23.10.11.
//  Released into the public domain.
//

#import "MLCLuaState.h"
#import "NSString+MLCExtensions.h"
#import <lauxlib.h>
#import <lualib.h>
#import <objc/runtime.h>

char * const MLCLuaStateLuaPathsKey = "LuaPaths";

@interface MLCLuaState ()
@property (nonatomic, readwrite) lua_State *state;
@property (nonatomic, assign) BOOL closeWhenDone;
@end

@implementation MLCLuaState
@synthesize state = m_state;
@synthesize closeWhenDone = m_closeWhenDone;

+ (NSArray *)luaPaths; {
	return objc_getAssociatedObject(self, MLCLuaStateLuaPathsKey);
}

+ (void)setLuaPaths:(NSArray *)paths; {
	objc_setAssociatedObject(self, MLCLuaStateLuaPathsKey, paths, OBJC_ASSOCIATION_COPY);
}

- (id)init {
	lua_State *state = luaL_newstate();
	if (!state)
		return nil;

	luaL_openlibs(state);

	self = [self initWithState:state closeWhenDone:YES];
	if (!self)
		return nil;

	return self;
}

- (id)initWithState:(lua_State *)state closeWhenDone:(BOOL)closeWhenDone; {
  	NSParameterAssert(state != NULL);

  	if ((self = [super init])) {
		self.state = state;
		self.closeWhenDone = closeWhenDone;

		lua_getglobal(self.state, "package.path");
		NSString *packagePath = [NSString valueFromStack:self atIndex:-1];
		
		NSString *additionalPaths = [[[self class] luaPaths] componentsJoinedByString:@";"];
		packagePath = [packagePath stringByAppendingFormat:@";%@", additionalPaths];

		[packagePath pushOntoStack:self];
		lua_setglobal(self.state, "package.path");
	}

	return self;
}

- (void)dealloc {
  	if (self.closeWhenDone) {
		lua_close(self.state);
		self.state = NULL;
	}
}

- (BOOL)loadString:(NSString *)source; {
  	// use the 'loadstring' loaded into Lua, because Metalua overrides the
	// default behavior to additionally compile Metalua code
  	lua_getglobal(self.state, "loadstring");

	[source pushOntoStack:self];
	lua_call(self.state, 1, 1);

	return !lua_isnil(self.state, -1);
}

@end
