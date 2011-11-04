//
//  MLCModel.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 30.10.11.
//  Released into the public domain.
//

#import "MLCModel.h"
#import "MLCState.h"
#import "EXTRuntimeExtensions.h"
#import <lauxlib.h>
#import <objc/runtime.h>

static char * const MLCModelClassAssociatedStateKey = "AssociatedMLCState";

@interface MLCModel ()
/**
 * Enumerates all the properties of the receiver and any superclasses, up until
 * the MLCModel class.
 */
+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property))block;

/**
 * Returns an array containing the names of all the model properties of the
 * receiver and any superclasses, up until the MLCModel class.
 */
+ (NSArray *)modelPropertyNames;

/**
 * Returns the #MLCState object for this model class. If no Lua state has yet
 * been set up, this will create one and attempt to load a Lua script with the
 * name of the current class and a .mlua or .lua extension.
 */
+ (MLCState *)state;

/**
 * Pushes onto the #state the metatable object meant for the receiver's
 * userdata.
 */
+ (void)pushUserdataMetatable;
@end

@implementation MLCModel

- (id)initWithDictionary:(NSDictionary *)dict; {
	self = [super init];
	if (!self)
		return nil;

	[self setValuesForKeysWithDictionary:dict];
	return self;
}

- (NSDictionary *)dictionaryValue; {
	NSArray *keys = [[self class] modelPropertyNames];
	return [self dictionaryWithValuesForKeys:keys];
}

+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property))block; {
	for (Class cls = self;cls != [MLCModel class];cls = [cls superclass]) {
		unsigned count = 0;
		objc_property_t *properties = class_copyPropertyList(cls, &count);

		if (!properties)
			continue;

		for (unsigned i = 0;i < count;++i) {
			block(properties[i]);
		}

		free(properties);
	}
}

+ (NSArray *)modelPropertyNames; {
	NSMutableArray *names = [[NSMutableArray alloc] init];

	[self enumeratePropertiesUsingBlock:^(objc_property_t property){
		const char *cName = property_getName(property);
		NSString *str = [[NSString alloc] initWithUTF8String:cName];

		[names addObject:str];
	}];

	return names;
}

+ (MLCState *)state; {
	MLCState *state = objc_getAssociatedObject(self, MLCModelClassAssociatedStateKey);
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
				NSLog(@"Could not initialize model Lua state: %@", error);
				return NO;
			}
			
			// dofile('CLASSNAME.mlua')
			if (![state callFunctionWithArgumentCount:0 resultCount:1 error:&error]) {
				NSLog(@"Could not initialize model Lua state: %@", error);
				return NO;
			}

			[state growStackBySize:2];

			// stack[LUA_REGISTRYINDEX]["CLASSNAME"] = {}
			if (luaL_newmetatable(state.state, cName)) {
				// __gc
				lua_pushcfunction(state.state, [self gcMetamethod]);
				lua_setfield(state.state, -2, "__gc");

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

		objc_setAssociatedObject(self, MLCModelClassAssociatedStateKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}

	return state;
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

		if (resultCount)
			[state popReturnValueForInvocation:invocation];

		return YES;
	}];
}

- (id)valueForUndefinedKey:(NSString *)key {
	// try invoking Lua
	MLCState *state = [[self class] state];

	__block id result = nil;

	[state enforceStackDelta:0 forBlock:^{
		[[self class] pushUserdataMetatable];
		[state popTableAndPushField:key];

		// push self as only argument
		[self pushOntoStack:state];

		NSError *error = nil;
		if (![state callFunctionWithArgumentCount:1 resultCount:1 error:&error]) {
			NSLog(@"Exception occurred when getting key %@ from Lua: %@", key, error);
			return NO;
		}

		result = [state popValueOnStack];
		return YES;
	}];

	return result;
}

+ (void)pushUserdataMetatable; {
	MLCState *state = [self state];

	NSString *name = NSStringFromClass(self);
	const char *cName = [name UTF8String];
	luaL_getmetatable(state.state, cName);
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder {
	NSDictionary *dict = [coder decodeObjectForKey:@"dictionaryValue"];
	return [self initWithDictionary:dict];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	NSDictionary *dict = [self dictionaryValue];
	if (dict)
		[coder encodeObject:dict forKey:@"dictionaryValue"];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

#pragma mark NSObject

- (NSUInteger)hash {
	return [[self dictionaryValue] hash];
}

- (BOOL)isEqual:(MLCModel *)model {
	// TODO: verify descendant classes, checking for a common ancestor
	if (![model isKindOfClass:[MLCModel class]])
		return NO;
	
	return [[self dictionaryValue] isEqual:[model dictionaryValue]];
}

#pragma mark MLCValue

+ (BOOL)isOnStack:(MLCState *)state; {
  	NSAssert1(state == [self state], @"%@ does not support using an MLCState that is not its own", self);

	if (!lua_isuserdata(state.state, -1))
		return NO;

	return [state enforceStackDelta:0 forBlock:^{
		lua_getmetatable(state.state, -1);
		[[self class] pushUserdataMetatable];

		BOOL equal = (BOOL)lua_equal(state.state, -2, -1);
		lua_pop(state.state, 2);

		return equal;
	}];
}

+ (id)popFromStack:(MLCState *)state; {
  	NSAssert1(state == [self state], @"%@ does not support using an MLCState that is not its own", self);

	if (![self isOnStack:state])
		return nil;
	
	void *userdata = lua_touserdata(state.state, -1);
	return [self objectFromUserdata:userdata transferringOwnership:NO];
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
