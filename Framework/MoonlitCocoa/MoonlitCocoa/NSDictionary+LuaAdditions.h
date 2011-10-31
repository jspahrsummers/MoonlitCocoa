//
//  NSDictionary+LuaAdditions.h
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 30.10.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>
#import <MoonlitCocoa/MLCValue.h>

@interface NSDictionary (LuaAdditions) <MLCValue>
/**
 * Returns \c YES if the value at the top of the Lua stack of \a state is
 * a table.
 */
+ (BOOL)isOnStack:(MLCState *)state;

/**
 * Pops a table off the top of the Lua stack of \a state. Returns \c nil if the
 * value at the top of the Lua stack is not a table.
 *
 * @note Any numeric indices in the table are converted to \c NSNumber keys.
 */
+ (id)popFromStack:(MLCState *)state;

/**
 * Pushes the receiver on the Lua stack of \a state.
 *
 * Any keys or values that do not conform to the #MLCValue protocol are pushed
 * as light userdata.
 */
- (void)pushOntoStack:(MLCState *)state;
@end
