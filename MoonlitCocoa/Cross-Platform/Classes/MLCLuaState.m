//
//  MLCLuaState.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 23.10.11.
//  Released into the public domain.
//

#import "MLCLuaState.h"
#import <lauxlib.h>
#import <lualib.h>

@interface MLCLuaState ()
@property (nonatomic, readwrite) lua_State *state;
@property (nonatomic, assign) BOOL closeWhenDone;
@end

@implementation MLCLuaState
@synthesize state = m_state;
@synthesize closeWhenDone = m_closeWhenDone;

- (id)init {
	lua_State *state = luaL_newstate();
	if (!state)
		return nil;

	self = [self initWithState:state closeWhenDone:YES];
	if (!self)
		return nil;

	luaL_openlibs(self.state);
	return self;
}

- (id)initWithState:(lua_State *)state closeWhenDone:(BOOL)closeWhenDone; {
  	NSParameterAssert(state != NULL);

  	if ((self = [super init])) {
		self.state = state;
		self.closeWhenDone = closeWhenDone;
	}

	return self;
}

- (void)dealloc {
  	if (self.closeWhenDone) {
		lua_close(self.state);
		self.state = NULL;
	}
}

@end
