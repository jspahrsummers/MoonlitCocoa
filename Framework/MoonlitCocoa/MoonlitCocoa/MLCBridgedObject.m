//
//  MLCBridgedObject.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 04.11.11.
//  Released into the public domain.
//

#import "MLCBridgedObject.h"
#import "MLCState.h"
#import <lauxlib.h>

/**
 * Invoked as the __gc metamethod on a userdata object. We take this opportunity
 * to balance the object's retain count.
 */
static int userdataGC (lua_State *state) {
	int args = lua_gettop(state);
	if (args < 1) {
		lua_pushliteral(state, "Not enough arguments to __gc metamethod");
		lua_error(state);
	}

	void *userdata = lua_touserdata(state, 1);
	if (!userdata) {
		lua_pushliteral(state, "No userdata object for argument 1");
		lua_error(state);
	}

	// transfer ownership to ARC and discard
	[MLCBridgedObject objectFromUserdata:userdata transferringOwnership:YES];

	// pop all arguments
	lua_pop(state, args);

	return 0;
}

/**
 * Used to compare two userdata objects. This implementation compares the object
 * pointers for identity.
 */
static int userdataEquals (lua_State *state) {
	int args = lua_gettop(state);
	if (args < 2) {
		lua_pushliteral(state, "Not enough arguments to __eq metamethod");
		lua_error(state);
	}

	void *userdataA = lua_touserdata(state, 1);
	if (!userdataA) {
		lua_pushliteral(state, "No userdata object for argument 1");
		lua_error(state);
	}

	void *userdataB = lua_touserdata(state, 2);
	if (!userdataB) {
		lua_pushliteral(state, "No userdata object for argument 2");
		lua_error(state);
	}

	id objA = [MLCBridgedObject objectFromUserdata:userdataA transferringOwnership:NO];
	id objB = [MLCBridgedObject objectFromUserdata:userdataB transferringOwnership:NO];

	// pop all arguments
	lua_pop(state, args);

	lua_pushboolean(state, (objA == objB));
	return 1;
}

@implementation MLCBridgedObject
+ (lua_CFunction)gcMetamethod; {
	return &userdataGC;
}

+ (lua_CFunction)eqMetamethod; {
	return &userdataEquals;
}

+ (id)objectFromUserdata:(void *)userdata transferringOwnership:(BOOL)transfer; {
	void **userdataContainingPtr = userdata;

	id obj = nil;
	
	if (transfer) {
		obj = (__bridge_transfer id)*userdataContainingPtr;
	} else {
		obj = (__bridge id)*userdataContainingPtr;
	}

	if ([obj isKindOfClass:self])
		return obj;
	else
		return nil;
}

@end
