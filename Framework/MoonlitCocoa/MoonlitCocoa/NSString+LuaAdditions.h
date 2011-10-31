//
//  NSString+LuaAdditions.h
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 30.10.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>
#import <MoonlitCocoa/MLCValue.h>

@interface NSString (LuaAdditions) <MLCValue>
/**
 * Returns \c YES if the value at the top of the Lua stack of \a state is
 * a string or number.
 */
+ (BOOL)isOnStack:(MLCState *)state;

/**
 * Pops a string off the top of the Lua stack of \a state. The string is assumed
 * to be encoded with UTF-8. Returns \c nil if the value at the top of the Lua
 * stack is not a string or number.
 *
 * @note The string on the stack may contain embedded NULs.
 */
+ (id)popFromStack:(MLCState *)state;

/**
 * Pushes the receiver on the Lua stack of \a state.
 *
 * @note The string is encoded with UTF-8 before being passed into Lua.
 */
- (void)pushOntoStack:(MLCState *)state;
@end
