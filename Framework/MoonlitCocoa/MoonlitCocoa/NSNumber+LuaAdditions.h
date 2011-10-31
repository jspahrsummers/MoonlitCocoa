//
//  NSNumber+LuaAdditions.h
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 30.10.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>
#import <MoonlitCocoa/MLCValue.h>

@interface NSNumber (LuaAdditions) <MLCValue>
/**
 * Returns \c YES if the value at the top of the Lua stack of \a state is
 * a number or a string convertible to a number.
 */
+ (BOOL)isOnStack:(MLCState *)state;

/**
 * Pops a number off the top of the Lua stack of \a state. Returns \c nil if the
 * value at the top of the Lua stack is not a number or a string convertible to
 * a number.
 */
+ (id)popFromStack:(MLCState *)state;

/**
 * Pushes the receiver on the Lua stack of \a state.
 */
- (void)pushOntoStack:(MLCState *)state;
@end
