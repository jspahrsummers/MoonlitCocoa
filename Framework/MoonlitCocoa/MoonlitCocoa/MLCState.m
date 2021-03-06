//
//  MLCState.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 24.10.11.
//  Released into the public domain.
//

#import "MLCState.h"
#import "MLCBridgedObject.h"
#import "MLCValue.h"
#import "NSDictionary+LuaAdditions.h"
#import "NSNull+LuaAdditions.h"
#import "NSNumber+LuaAdditions.h"
#import "NSString+LuaAdditions.h"
#import <lauxlib.h>
#import <lualib.h>
#import <objc/runtime.h>

NSString * const MLCLuaErrorDomain = @"MLCLuaErrorDomain";
NSString * const MLCLuaStackOverflowException = @"MLCLuaStackOverflowException";

/**
 * Trampolines a Lua function call into an Objective-C invocation.
 */
static int trampolineToObjectiveC (lua_State *L) {
	int args = lua_gettop(L);
	if (args < 1) {
		lua_pushliteral(L, "No object included in Lua to Objective-C function call");
		lua_error(L);
	}

	if (args < 2) {
		lua_pushliteral(L, "No selector included in Lua to Objective-C function call");
		lua_error(L);
	}

	int stateIndex = lua_upvalueindex(1);

	// get the MLCState object associated with this Lua state
	MLCState *state = (__bridge id)lua_touserdata(L, stateIndex);
	if (!state) {
		lua_pushliteral(L, "Could not get MLCState associated with Lua state");
		lua_error(L);
	}

	if (L != state.state) {
		lua_pushliteral(L, "Given MLCState upvalue is not associated with the current Lua state");
		lua_error(L);
	}

	// get the object upon which to invoke this method
	id target = [state getValueAtStackIndex:1];

	// get the selector that this function is trying to call
	const char *selectorString = lua_tostring(L, 2);
	SEL selector = sel_registerName(selectorString);

	NSMethodSignature *signature = [target methodSignatureForSelector:selector];
	if (!signature) {
		NSString *errorMessage = [NSString stringWithFormat:@"%@ does not recognize selector %s", target, selector];
		[state pushObject:errorMessage];

		lua_error(L);
	}

	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	NSInteger methodArgumentCount = (NSInteger)[signature numberOfArguments];

	@autoreleasepool {
		[invocation setTarget:target];
		[invocation setSelector:selector];

		for (NSInteger i = methodArgumentCount - 1;i > 2;--i) {
			// any arguments required by the method but not passed from the Lua
			// script get filled with nil, matching Lua semantics
			__autoreleasing id obj = nil;

			if (i < args) {
				obj = [state popValueOnStack];
			}

			[invocation setArgument:&obj atIndex:i];
		}

		[invocation invoke];

		NSUInteger returnLength = [signature methodReturnLength];
		if (!returnLength)
			return 0;

		unsigned char buffer[returnLength];

		[invocation getReturnValue:buffer];
		[state pushValue:buffer objCType:[signature methodReturnType]];
		return 1;
	}
}

@interface MLCState ()
@property (nonatomic, readwrite) lua_State *state;
@end

@implementation MLCState
@synthesize state = m_state;

+ (lua_CFunction)trampolineFunction; {
	return &trampolineToObjectiveC;
}

+ (id)state; {
	return [[self alloc] init];
}

- (id)init; {
  	self = [super init];
	if (!self)
		return nil;
	
	self.state = luaL_newstate();
	luaL_openlibs(self.state);

	// add additional package paths (including the path used by Homebrew)
	[self growStackBySize:2];
	[self enforceStackDelta:0 forBlock:^{
		[self pushGlobal:@"package"];

		lua_pushliteral(self.state, ";;?;?.lua;?.luac;/usr/local/lib/?.luac;/usr/local/lib/?.lua");
		lua_setfield(self.state, -2, "path");
		lua_pop(self.state, 1);
		return YES;
	}];

	// initialize Metalua compiler
	BOOL result = [self enforceStackDelta:0 forBlock:^{
		NSString *compilerPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"compiler" ofType:@"lua"];
		if (0 != luaL_dofile(self.state, [compilerPath UTF8String])) {
			NSLog(@"Could not load Metalua compiler: %@", [NSString popFromStack:self]);
			return NO;
		}

		return YES;
	}];

	if (!result)
		return nil;
	else
		return self;
}

- (void)dealloc {
  	if (self.state) {
		lua_close(self.state);
		self.state = NULL;
	}
}

- (BOOL)callFunctionWithArgumentCount:(int)argCount resultCount:(int)resultCount error:(NSError **)error; {
	int ret = lua_pcall(self.state, argCount, resultCount, 0);
	if (ret == 0) {
		return YES;
	} else {
		if (error) {
			NSDictionary *userInfo = nil;
			NSString *message = [NSString popFromStack:self];
			if (message) {
				userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
			}

			*error = [NSError
				errorWithDomain:MLCLuaErrorDomain
				code:ret
				userInfo:userInfo
			];
		}

		return NO;
	}
}

- (id)getValueAtStackIndex:(int)index; {
  	[self growStackBySize:1];

	// duplicate the value in the stack, so that we can pop and then leave the
	// stack in its previous state
  	lua_pushvalue(self.state, index);

	return [self popValueOnStack];
}

- (BOOL)loadScript:(NSString *)source error:(NSError **)error; {
	source = [@"require 'metalua.runtime'\n\n" stringByAppendingString:source];
  
  	[self growStackBySize:2];

	return [self enforceStackDelta:1 forBlock:^{
		[self pushGlobal:@"compiler"];
		[self popTableAndPushField:@"loadstring"];

		[source pushOntoStack:self];

		NSError *localError = nil;

		// on the stack should be:
		// { compiler.loadstring, source }
		if (![self callFunctionWithArgumentCount:1 resultCount:1 error:&localError]) {
			NSLog(@"Could not load script: %@", localError);

			if (error)
				*error = localError;

			return NO;
		} else {
			return YES;
		}
	}];
}

- (BOOL)loadScriptAtURL:(NSURL *)URL error:(NSError **)error; {
  	NSString *source = [NSString stringWithContentsOfURL:URL usedEncoding:NULL error:error];
	if (!source)
		return NO;
	
	return [self loadScript:source error:error];
}

- (BOOL)enforceStackDelta:(int)delta forBlock:(BOOL (^)(void))block; {
  	int top = lua_gettop(self.state);
	BOOL result = block();
	int newTop = lua_gettop(self.state);

	NSAssert2(newTop == top + delta, @"Actual stack delta (%i) does not match expected delta (%i)", newTop - top, delta);

	return result;
}

- (void)growStackBySize:(int)size; {
  	if (!lua_checkstack(self.state, size)) {
		[NSException raise:MLCLuaStackOverflowException format:@"Could not grow Lua stack by %i slots", size];
	}
}

- (void)popTableAndPushField:(NSString *)field; {
	[self growStackBySize:1];
  	lua_getfield(self.state, -1, [field UTF8String]);

	// replace the original table in the stack
	lua_replace(self.state, -2);
}

- (void)popTableAndPushMetatable; {
  	[self growStackBySize:1];
	lua_getmetatable(self.state, -1);

	// replace the original table in the stack
	lua_replace(self.state, -2);
}

- (id)popValueOnStack; {
	__block id result = nil;

	[self enforceStackDelta:-1 forBlock:^{
		switch (lua_type(self.state, -1)) {
		case LUA_TNIL:
			result = [NSNull popFromStack:self];
			break;

		case LUA_TNUMBER:
		case LUA_TBOOLEAN:
			result = [NSNumber popFromStack:self];
			break;

		case LUA_TSTRING:
			result = [NSString popFromStack:self];
			break;

		case LUA_TTABLE:
			result = [NSDictionary popFromStack:self];
			break;

		case LUA_TUSERDATA:
			result = [MLCBridgedObject popFromStack:self];
			break;

		case LUA_TLIGHTUSERDATA:
			result = (__bridge id)lua_touserdata(self.state, -1);
			lua_pop(self.state, 1);
			break;
		
		case LUA_TTHREAD:
		case LUA_TFUNCTION:
			// TODO: not yet implemented
		
		default:
			lua_pop(self.state, 1);
			return NO;
		}

		return YES;
	}];

	return result;
}

- (void)pushArgumentsOfInvocation:(NSInvocation *)invocation; {
	NSMethodSignature *signature = [invocation methodSignature];
	int count = (int)[signature numberOfArguments];

	if (count <= 2)
		return;
	
	[self growStackBySize:count - 2];

	// buffer to hold untyped argument data
	unsigned char buffer[[signature frameLength]];

	for (int i = 2;i < count;++i) {
		const char *type = [signature getArgumentTypeAtIndex:(NSUInteger)i];
		[invocation getArgument:buffer atIndex:i];
		[self pushValue:buffer objCType:type];
	}
}

- (BOOL)pushValue:(void *)buffer objCType:(const char *)type; {
	// skip attributes in the provided type encoding
	while (
		*type == 'r' ||
		*type == 'n' ||
		*type == 'N' ||
		*type == 'o' ||
		*type == 'O' ||
		*type == 'R' ||
		*type == 'V'
	) {
		++type;
	}

	return [self enforceStackDelta:1 forBlock:^{
		#define pushNumberOfType(TYPE) \
			do { \
				TYPE num; \
				memcpy(&num, buffer, sizeof(num)); \
				lua_pushnumber(self.state, (lua_Number)num); \
			} while (0)

		switch (*type) {
		case 'c':
			// single characters are pushed as numbers because BOOL is
			// typedef'd to 'char'
			pushNumberOfType(signed char);
			break;

		case 'C':
			pushNumberOfType(unsigned char);
			break;

		case 'i':
			pushNumberOfType(int);
			break;

		case 'I':
			pushNumberOfType(unsigned int);
			break;

		case 's':
			pushNumberOfType(short);
			break;

		case 'S':
			pushNumberOfType(unsigned short);
			break;

		case 'l':
			pushNumberOfType(long);
			break;

		case 'L':
			pushNumberOfType(unsigned long);
			break;

		case 'q':
			pushNumberOfType(long long);
			break;

		case 'Q':
			pushNumberOfType(unsigned long long);
			break;

		case 'f':
			pushNumberOfType(float);
			break;

		case 'd':
			pushNumberOfType(double);
			break;

		case 'B':
			{
				_Bool b;
				memcpy(&b, buffer, sizeof(b));
				lua_pushboolean(self.state, b);
			}

			break;

		case '*':
			{
				const char *str;
				memcpy(&str, buffer, sizeof(str));
				lua_pushstring(self.state, str);
			}

			break;

		case ':':
			{
				SEL selector;
				memcpy(&selector, buffer, sizeof(selector));

				const char *name = sel_getName(selector);
				lua_pushstring(self.state, name);
			}

			break;

		case '@':
		case '#':
			{
				__unsafe_unretained id obj;
				memcpy(&obj, buffer, sizeof(obj));

				id strongObj = obj;
				[self pushObject:strongObj];
			}

			break;

		case '^':
			{
				void *ptr;
				memcpy(&ptr, buffer, sizeof(ptr));
				lua_pushlightuserdata(self.state, ptr);
			}

			break;

		default:
			NSLog(@"Unsupported argument type \"%s\", pushing nil", type);
			lua_pushnil(self.state);
			return NO;
		}

		return YES;
	}];
}

- (BOOL)popReturnValueForInvocation:(NSInvocation *)invocation; {
	NSMethodSignature *signature = [invocation methodSignature];

	NSUInteger returnLength = [signature methodReturnLength];
	if (!returnLength)
		return YES;

	const char *type = [signature methodReturnType];
	unsigned char buffer[returnLength];

	BOOL success = [self popValue:buffer objCType:type];
	[invocation setReturnValue:buffer];

	return success;
}

- (BOOL)popValue:(void *)buffer objCType:(const char *)type; {
	// skip attributes in the provided type encoding
	while (
		*type == 'r' ||
		*type == 'n' ||
		*type == 'N' ||
		*type == 'o' ||
		*type == 'O' ||
		*type == 'R' ||
		*type == 'V'
	) {
		++type;
	}

	#define popNSNumberValue(TYPE, NAME) \
		do { \
			NSNumber *numObj = [NSNumber popFromStack:self]; \
			TYPE num = [numObj NAME ## Value]; \
			memcpy(buffer, &num, sizeof(num)); \
		} while (0)

	switch (*type) {
	case 'c':
		popNSNumberValue(char, char);
		break;

	case 'C':
		popNSNumberValue(unsigned char, unsignedChar);
		break;

	case 'i':
		popNSNumberValue(int, int);
		break;

	case 'I':
		popNSNumberValue(unsigned int, unsignedInt);
		break;

	case 's':
		popNSNumberValue(short, short);
		break;

	case 'S':
		popNSNumberValue(unsigned short, unsignedShort);
		break;

	case 'l':
		popNSNumberValue(long, long);
		break;

	case 'L':
		popNSNumberValue(unsigned long, unsignedLong);
		break;

	case 'q':
		popNSNumberValue(long long, longLong);
		break;

	case 'Q':
		popNSNumberValue(unsigned long long, unsignedLongLong);
		break;
	
	case 'f':
		popNSNumberValue(float, float);
		break;
	
	case 'd':
		popNSNumberValue(double, double);
		break;
	
	case 'B':
		popNSNumberValue(_Bool, bool);
		break;
	
	case 'v':
		// no return value, nothing to do
		break;
	
	case '*':
		{
			size_t length = 0;
			const char *str = lua_tolstring(self.state, -1, &length);

			// create a junk NSData, added to the autorelease pool, to hold this
			// string data and automatically release it
			__autoreleasing NSData *data = [NSData dataWithBytes:str length:length];

			// pop the string, potentially garbage collecting it
			lua_pop(self.state, 1);

			str = [data bytes];
			memcpy(buffer, &str, sizeof(str));
		}

		break;
	
	case '@':
	case '#':
		{
			__autoreleasing id obj = [self popValueOnStack];

			__unsafe_unretained id unsafeObj = obj;
			memcpy(buffer, &unsafeObj, sizeof(unsafeObj));
		}

		break;
	
	case ':':
		{
			const char *str = lua_tostring(self.state, -1);
			SEL selector = sel_registerName(str);

			// pop the string, potentially garbage collecting it
			lua_pop(self.state, 1);

			memcpy(buffer, &selector, sizeof(selector));
		}
		
		break;
	
	case '^':
		{
			void *ptr = (void *)lua_topointer(self.state, -1);
			memcpy(buffer, &ptr, sizeof(ptr));
		}

		break;

	default:
		{
			NSUInteger size = 0;
			NSGetSizeAndAlignment(buffer, &size, NULL);

			memset(buffer, 0, size);
		}

		return NO;
	}

	return YES;
}

- (void)pushGlobal:(NSString *)symbol; {
	[self growStackBySize:1];
	lua_getglobal(self.state, [symbol UTF8String]);
}

- (void)pushObject:(id)object; {
	if ([object respondsToSelector:@selector(pushOntoStack:)]) {
		[object pushOntoStack:self];
		return;
	}

	[self growStackBySize:1];

  	if (!object) {
		lua_pushnil(self.state);
	} else {
		lua_pushlightuserdata(self.state, (__bridge void *)object);
	}
}

@end
