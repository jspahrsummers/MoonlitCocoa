//
//  NSString+LuaAdditions.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 30.10.11.
//  Released into the public domain.
//

#import "NSString+LuaAdditions.h"
#import "MLCState.h"
#import <lua.h>

@implementation NSString (LuaAdditions)
+ (BOOL)isOnStack:(MLCState *)state; {
	return (BOOL)lua_isstring(state.state, -1);
}

+ (id)popFromStack:(MLCState *)state; {
  	size_t len = 0;
	const char *cStr = lua_tolstring(state.state, -1, &len);
	if (!cStr)
		return nil;
	
	lua_pop(state.state, 1);
	
	return [[self alloc] initWithBytes:cStr length:len encoding:NSUTF8StringEncoding];
}

- (void)pushOntoStack:(MLCState *)state; {
	[state growStackBySize:1];

  	NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
	lua_pushlstring(state.state, [data bytes], [data length]);
}
@end
