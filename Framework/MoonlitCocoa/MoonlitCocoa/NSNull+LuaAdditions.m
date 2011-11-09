//
//  NSNull+LuaAdditions.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 30.10.11.
//  Released into the public domain.
//

#import "NSNull+LuaAdditions.h"
#import "MLCState.h"
#import <lua.h>

@implementation NSNull (LuaAdditions)
+ (BOOL)isOnStack:(MLCState *)state; {
	return (BOOL)lua_isnil(state.state, -1);
}

+ (id)popFromStack:(MLCState *)state; {
	BOOL isOnStack = [self isOnStack:state];

	lua_pop(state.state, 1);
	if (isOnStack)
		return [self null];
	else
		return nil;
}

- (void)pushOntoStack:(MLCState *)state; {
  	lua_pushnil(state.state);
}
@end
