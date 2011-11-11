//
//  NSArray+LuaAdditions.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 10.11.11.
//  Released into the public domain.
//

#import "NSArray+LuaAdditions.h"
#import "MLCState.h"
#import <lua.h>

@implementation NSArray (LuaAdditions)
+ (BOOL)isOnStack:(MLCState *)state; {
	return (BOOL)lua_istable(state.state, -1);
}

+ (id)popFromStack:(MLCState *)state; {
	if (![self isOnStack:state]) {
		lua_pop(state.state, 1);
		return nil;
	}

	size_t length = lua_objlen(state.state, -1);
	if (!length) {
		// empty table
		lua_pop(state.state, 1);
		return [NSArray array];
	}

	// zeroing out the array will help in catching bugs, but it shouldn't be
	// necessary and can't be considered a fix for missing elements (since
	// initializing an array with a nil object will throw an exception anyways)
	__strong id *values = (__strong id *)calloc(length, sizeof(*values));
	if (!values) {
		lua_pop(state.state, 1);
		return nil;
	}

	// space for the key used during iteration
	[state growStackBySize:1];

	[state enforceStackDelta:-1 forBlock:^{
		lua_pushnil(state.state);

		while (lua_next(state.state, -2) != 0) {
			// key is now at -2
			// value is now at -1
			
			NSUInteger index = (NSUInteger)lua_tonumber(state.state, -2);
			if (index == 0 || index > length) {
				// this index is non-numeric or out-of-order -- skip it (popping
				// the value from the stack)
				lua_pop(state.state, 1);
				continue;
			}

			id value = [state popValueOnStack];
			
			// Lua indices start at one, so adjust appropriately
			values[index - 1] = value;
		}

		// pop the key and the table
		lua_pop(state.state, 2);

		return YES;
	}];

	NSArray *array = [[self alloc] initWithObjects:values count:length];
	free(values);

	return array;
}

- (void)pushOntoStack:(MLCState *)state; {
	// reserve space for a new table
	[state growStackBySize:1];

	[state enforceStackDelta:1 forBlock:^{
		NSUInteger count = [self count];
		if (count <= INT_MAX) {
			lua_createtable(state.state, (int)count, 0);
		} else {
			lua_newtable(state.state);
		}

		lua_Number index = 1;
		for (id value in self) {
			lua_pushnumber(state.state, index);
			[state pushObject:value];

			// t[index] = value
			lua_settable(state.state, -2);
		}

		return YES;
	}];
}

@end
