//
//  NSDecimalNumber+LuaAdditions.h
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 10.11.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>
#import <MoonlitCocoa/MLCValue.h>

@interface NSDecimalNumber (LuaAdditions) <MLCValue>
/**
 * Returns \c YES if the value at the top of the Lua stack of \a state is
 * a number or a string convertible to a number.
 *
 * @note Unlike the \c NSNumber extensions, this will return \c NO for a boolean
 * value on the stack.
 */
+ (BOOL)isOnStack:(MLCState *)state;

/**
 * Pops a number off the top of the Lua stack of \a state. Returns \c nil if the
 * value at the top of the Lua stack is not a number or a string convertible to
 * a number.
 *
 * @note Unlike the \c NSNumber extensions, this will return \c nil for a boolean
 * value on the stack.
 */
+ (id)popFromStack:(MLCState *)state;

/**
 * Pushes the receiver on the Lua stack of \a state as a string.
 */
- (void)pushOntoStack:(MLCState *)state;
@end
