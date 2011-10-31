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
	if (![self isOnStack:state])
		return nil;

	lua_pop(state.state, 1);
	return [self null];
}

- (void)pushOntoStack:(MLCState *)state; {
  	lua_pushnil(state.state);
}
@end
