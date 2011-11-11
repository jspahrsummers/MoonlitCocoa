//
//  NSDecimalNumber+LuaAdditions.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 10.11.11.
//  Released into the public domain.
//

#import "NSDecimalNumber+LuaAdditions.h"
#import "NSString+LuaAdditions.h"
#import "MLCState.h"

@implementation NSDecimalNumber (LuaAdditions)
+ (BOOL)isOnStack:(MLCState *)state; {
	return (BOOL)lua_isnumber(state.state, -1);
}

+ (id)popFromStack:(MLCState *)state; {
	if (![self isOnStack:state])
		return nil;

	NSString *str = [NSString popFromStack:state];
	if (!str)
		return nil;
	
	return [NSDecimalNumber decimalNumberWithString:str];
}

- (void)pushOntoStack:(MLCState *)state; {
	[[self stringValue] pushOntoStack:state];
}
@end
