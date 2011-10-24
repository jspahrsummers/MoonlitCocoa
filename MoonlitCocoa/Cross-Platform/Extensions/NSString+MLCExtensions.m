//
//  NSString+MLCExtensions.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 23.10.11.
//  Released into the public domain.
//

#import "NSString+MLCExtensions.h"
#import "MLCState.h"

@implementation NSString (MLCExtensions)
+ (BOOL)isInStack:(MLCState *)state atIndex:(int)index; {
	return (BOOL)lua_isstring(state.state, index);
}

+ (id)valueFromStack:(MLCState *)state atIndex:(int)index; {
  	size_t length = 0;
	const char *str = lua_tolstring(state.state, index, &length);
	if (!str)
		return nil;
	
	return [[self alloc] initWithBytes:str length:length encoding:NSUTF8StringEncoding];
}

- (void)pushOntoStack:(MLCState *)state; {
  	NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
  	lua_pushlstring(state.state, [data bytes], [data length]);
}
@end
