//
//  NSDictionary+LuaAdditions.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 30.10.11.
//  Released into the public domain.
//

#import "NSDictionary+LuaAdditions.h"
#import "MLCState.h"
#import <lua.h>

@implementation NSDictionary (LuaAdditions)
+ (BOOL)isOnStack:(MLCState *)state; {
	return (BOOL)lua_istable(state.state, -1);
}

+ (id)popFromStack:(MLCState *)state; {
	if (![self isOnStack:state]) {
		return nil;
	}

	size_t length = lua_objlen(state.state, -1);

	// space for the key used during iteration, plus a slot for string
	// conversions
	[state growStackBySize:2];

	NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:length];

	[state enforceStackDelta:-1 forBlock:^{
		lua_pushnil(state.state);

		while (lua_next(state.state, -2) != 0) {
			// key is now at -2
			// value is now at -1
			id value = [state popValueOnStack];
			if (!value)
				continue;

			id key = [state getValueOnStack];
			if (!key)
				continue;

			[dict setObject:value forKey:key];
		}

		// pop the key and the table
		lua_pop(state.state, 2);

		return YES;
	}];

	return [[self alloc] initWithDictionary:dict];
}

- (void)pushOntoStack:(MLCState *)state; {
  	// a new table, plus temporary space for key and value manipulation
  	[state growStackBySize:3];

	void (^pushObjectOntoStack)(id) = ^(id object){
		if ([object respondsToSelector:@selector(pushOntoStack:)]) {
			[object pushOntoStack:state];
		} else {
			lua_pushlightuserdata(state.state, (__bridge void *)object);
		}
	};

	[state enforceStackDelta:1 forBlock:^{
		NSUInteger count = [self count];
		if (count <= INT_MAX) {
			lua_createtable(state.state, 0, (int)count);
		} else {
			lua_newtable(state.state);
		}

		for (id key in self) {
			id value = [self objectForKey:key];

			pushObjectOntoStack(key);
			pushObjectOntoStack(value);
			lua_settable(state.state, -2);
		}

		return YES;
	}];
}
@end
