//
//  NSNumber+LuaAdditions.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 30.10.11.
//  Released into the public domain.
//

#import "NSNumber+LuaAdditions.h"
#import "MLCState.h"

@implementation NSNumber (LuaAdditions)
+ (BOOL)isOnStack:(MLCState *)state; {
	return lua_isboolean(state.state, -1) || lua_isnumber(state.state, -1);
}

+ (id)popFromStack:(MLCState *)state; {
	NSNumber *obj = nil;
	if (lua_isboolean(state.state, -1)) {
		obj = [NSNumber numberWithBool:(BOOL)lua_toboolean(state.state, -1)];
	} else if (!lua_isnumber(state.state, -1)) {
		double num = lua_tonumber(state.state, -1);
		obj = [NSNumber numberWithDouble:num];
	}

	if (obj)
		lua_pop(state.state, 1);
	
	return obj;
}

- (void)pushOntoStack:(MLCState *)state; {
	[state growStackBySize:1];

  	lua_pushnumber(state.state, [self doubleValue]);
}

@end
