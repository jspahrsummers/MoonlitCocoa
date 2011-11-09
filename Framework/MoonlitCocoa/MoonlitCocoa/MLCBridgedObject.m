//
//	MLCBridgedObject.m
//	MoonlitCocoa
//
//	Created by Justin Spahr-Summers on 04.11.11.
//	Released into the public domain.
//

#import "MLCBridgedObject.h"
#import "MLCState.h"
#import <lauxlib.h>
#import <objc/runtime.h>

static char * const MLCBridgedClassAssociatedStateKey = "AssociatedMLCState";

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
 * A closure which takes two upvalues (\c self and \c _cmd), passing them and
 * all of its arguments to the MLCState#trampolineFunction. The #MLCState object
 * for the \c self upvalue is passed as the only upvalue to the trampoline
 * function.
 */
static int trampolineTrampoline (lua_State *state) {
	int args = lua_gettop(state);

	int selfIndex = lua_upvalueindex(1);
	int cmdIndex = lua_upvalueindex(2);

	void *userdata = lua_touserdata(state, selfIndex);
	if (!userdata) {
		lua_pushliteral(state, "No 'self' object captured in closure");
		lua_error(state);
	}

	const char *selectorName = lua_tostring(state, cmdIndex);
	if (!selectorName) {
		lua_pushliteral(state, "No '_cmd' value captured in closure");
		lua_error(state);
	}

	MLCBridgedObject *obj = [MLCBridgedObject objectFromUserdata:userdata transferringOwnership:NO];

	// push the MLCState for the bridged object
	MLCState *stateObj = [[obj class] state];
	lua_pushlightuserdata(state, (__bridge void *)stateObj);

	// push MLCState's trampoline function, capturing the MLCState as an upvalue
	lua_pushcclosure(state, [[stateObj class] trampolineFunction], 1);

	// move the trampoline below all of the arguments to this function, per
	// function calling conventions
	lua_insert(state, 1);

	// copy the userdata argument to the top of the stack, then move it down to
	// the first argument position
	lua_pushvalue(state, selfIndex);
	lua_insert(state, 2);

	// same with _cmd, for the second argument
	lua_pushvalue(state, cmdIndex);
	lua_insert(state, 3);

	lua_call(state, args + 2, LUA_MULTRET);

	// at this point, the stack should contain only return values (now that
	// the function and all arguments have been popped), so the number of
	// results is the size of the stack
	return lua_gettop(state);
}

/**
 * Invoked as the __index metamethod on a userdata object. Returns a trampoline
 * invoking a method named after the key on the bridged userdata object.
 */
static int userdataIndex (lua_State *state) {
	int args = lua_gettop(state);
	if (args < 2) {
		lua_pushliteral(state, "Not enough arguments to __index metamethod");
		lua_error(state);
	}

	// pop all arguments not 'self' or '_cmd'
	lua_pop(state, args - 2);

	// push the closure onto the stack, using the existing arguments as upvalues
	lua_pushcclosure(state, &trampolineTrampoline, 2);

	return 1;
}

/**
 * Used to compare two userdata objects. This implementation compares the
 * objects for equality using -isEqual:.
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

	lua_pushboolean(state, [objA isEqual:objB]);
	return 1;
}

@implementation MLCBridgedObject
+ (BOOL)accessInstanceVariablesDirectly {
	return NO;
}

+ (MLCState *)state; {
	MLCState *state = objc_getAssociatedObject(self, MLCBridgedClassAssociatedStateKey);
	if (!state) {
		NSBundle *bundle = [NSBundle bundleForClass:self];
		NSString *name = NSStringFromClass([self class]);

		NSURL *scriptURL = [bundle URLForResource:name withExtension:@"mlua"];
		if (!scriptURL) {
			scriptURL = [bundle URLForResource:name withExtension:@"lua"];

			if (!scriptURL) {
				// could not find a script for this class
				return nil;
			}
		}

		state = [[MLCState alloc] init];
		const char *cName = [name UTF8String];

		BOOL success = [state enforceStackDelta:0 forBlock:^{
			NSError *error = nil;

			if (![state loadScriptAtURL:scriptURL error:&error]) {
				NSLog(@"Could not initialize Lua state for %@: %@", self, error);
				return NO;
			}

			// dofile('CLASSNAME.mlua')
			if (![state callFunctionWithArgumentCount:0 resultCount:1 error:&error]) {
				NSLog(@"Could not initialize Lua state for %@: %@", self, error);
				return NO;
			}

			[state growStackBySize:2];

			// stack[LUA_REGISTRYINDEX]["CLASSNAME"] = {}
			if (luaL_newmetatable(state.state, cName)) {
				// __gc
				lua_pushcfunction(state.state, [self gcMetamethod]);
				lua_setfield(state.state, -2, "__gc");

				// __index
				lua_pushcfunction(state.state, [self indexMetamethod]);
				lua_setfield(state.state, -2, "__index");

				// __eq
				lua_pushcfunction(state.state, [self eqMetamethod]);
				lua_setfield(state.state, -2, "__eq");
			}

			// space for two key/value pairs
			[state growStackBySize:4];

			// first key for next()
			lua_pushnil(state.state);

			// script table is now at index -3
			// empty metatable is now at index -2
			// key is at index -1

			// we want to copy all the keys and values from the table at -3 to -2
			while (lua_next(state.state, -3) != 0) {
				// script table is now at index -4
				// empty metatable is now at index -3
				// key is at index -2
				// value is at index -1

				[state enforceStackDelta:0 forBlock:^{
					// duplicate key to the top of the stack (because we can't pop
					// the one lua_next is using)
					lua_pushvalue(state.state, -2);

					// duplicate value to the top of the stack (because it has to
					// follow the key)
					lua_pushvalue(state.state, -2);

					// script table is now at index -6
					// empty metatable is now at index -5
					// key is at index -2
					// value is at index -1

					// copy the key and value into our metatable
					lua_settable(state.state, -5);

					return YES;
				}];

				// script table is now at index -4
				// empty metatable is now at index -3
				// original key is at index -2
				// original value is at index -1

				// pop original value in the stack
				lua_pop(state.state, 1);
			}

			// pop the script table and the metatable
			lua_pop(state.state, 2);

			return YES;
		}];

		if (!success)
			return nil;

		objc_setAssociatedObject(self, MLCBridgedClassAssociatedStateKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}

	return state;
}

+ (void)pushUserdataMetatable; {
	MLCState *state = [self state];

	NSString *name = NSStringFromClass(self);
	const char *cName = [name UTF8String];
	luaL_getmetatable(state.state, cName);
}

+ (lua_CFunction)gcMetamethod; {
	return &userdataGC;
}

+ (lua_CFunction)indexMetamethod; {
	return &userdataIndex;
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

#pragma mark Forwarding

+ (BOOL)metatableHasValueForKey:(NSString *)key; {
	MLCState *state = [self state];

	return [state enforceStackDelta:0 forBlock:^ BOOL {
		[self pushUserdataMetatable];
		[state popTableAndPushField:key];
		
		id obj = [state popValueOnStack];

		// if the value on the stack is 'nil' (and not anything else), we can
		// assume that this key does not exist
		return ![obj isEqual:[NSNull null]];
	}];
}

+ (BOOL)instancesRespondToSelector:(SEL)aSelector; {
	if ([super instancesRespondToSelector:aSelector])
		return YES;

	NSString *selectorName = NSStringFromSelector(aSelector);
	return [self metatableHasValueForKey:selectorName];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	NSMethodSignature *signature = [invocation methodSignature];

	NSString *selectorName = NSStringFromSelector([invocation selector]);
	int argumentCount = (int)[signature numberOfArguments];

	int resultCount;
	if ([signature methodReturnLength])
		resultCount = 1;
	else
		resultCount = 0;

	MLCState *state = [[self class] state];

	[state enforceStackDelta:0 forBlock:^{
		[[self class] pushUserdataMetatable];
		[state popTableAndPushField:selectorName];

		// push self as first argument
		[self pushOntoStack:state];
		[state pushArgumentsOfInvocation:invocation];

		NSError *error = nil;
		if (![state callFunctionWithArgumentCount:argumentCount - 1 resultCount:resultCount error:&error]) {
			NSLog(@"Exception occurred when invoking %@ in Lua: %@", selectorName, error);
			return NO;
		}

		[state popReturnValueForInvocation:invocation];
		return YES;
	}];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	return [[self class] instancesRespondToSelector:aSelector];
}

- (id)valueForUndefinedKey:(NSString *)key {
	// try invoking Lua
	MLCState *state = [[self class] state];

	__block id result = nil;

	[state enforceStackDelta:0 forBlock:^{
		[[self class] pushUserdataMetatable];
		[state popTableAndPushField:key];

		result = [state getValueAtStackIndex:-1];
		if ([result isEqual:[NSNull null]]) {
			[NSException raise:NSUndefinedKeyException format:@"Key \"%@\" not found on object %@ (in Objective-C or Lua)", key, self];
		}

		if (result) {
			lua_pop(state.state, 1);
		} else {
			// push self as only argument
			[self pushOntoStack:state];

			NSError *error = nil;
			if (![state callFunctionWithArgumentCount:1 resultCount:1 error:&error]) {
				NSLog(@"Exception occurred when getting key %@ from Lua: %@", key, error);
				return NO;
			}

			result = [state popValueOnStack];
		}

		return YES;
	}];

	return result;
}

#pragma mark MLCValue

+ (BOOL)isOnStack:(MLCState *)state; {
	if (!lua_isuserdata(state.state, -1))
		return NO;

	// compare metatables only for specific subclasses
	if (self != [MLCBridgedObject class]) {
		NSAssert1(state == [self state], @"%@ does not support using an MLCState that is not its own", self);

		return [state enforceStackDelta:0 forBlock:^{
			lua_getmetatable(state.state, -1);
			[[self class] pushUserdataMetatable];

			BOOL equal = (BOOL)lua_equal(state.state, -2, -1);
			lua_pop(state.state, 2);

			return equal;
		}];
	} else {
		return YES;
	}
}

+ (id)popFromStack:(MLCState *)state; {
	if (![self isOnStack:state]) {
		lua_pop(state.state, 1);
		return nil;
	}

	void *userdata = lua_touserdata(state.state, -1);
	lua_pop(state.state, 1);

	id obj = [self objectFromUserdata:userdata transferringOwnership:NO];

	NSAssert1(state == [[obj class] state], @"%@ does not support using an MLCState that is not its own", obj);
	return obj;
}

- (void)pushOntoStack:(MLCState *)state; {
	NSAssert1(state == [[self class] state], @"%@ does not support using an MLCState that is not its own", self);

	// userdata + metatable
	[state growStackBySize:2];

	[state enforceStackDelta:1 forBlock:^{
		// create a userdata object containing a pointer to 'self'
		void *ptr = lua_newuserdata(state.state, sizeof(void *));
		void *selfPtr = (__bridge_retained void *)self;
		memcpy(ptr, &selfPtr, sizeof(void *));

		// set up a standard metatable on the object
		[[self class] pushUserdataMetatable];
		lua_setmetatable(state.state, -2);

		return YES;
	}];
}

@end
