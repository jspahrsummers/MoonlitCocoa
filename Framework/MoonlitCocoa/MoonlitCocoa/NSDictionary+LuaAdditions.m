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
	return nil;
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
