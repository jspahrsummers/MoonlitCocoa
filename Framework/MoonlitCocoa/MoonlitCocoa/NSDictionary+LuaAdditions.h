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
 * Any numeric indices in the table are converted to \c NSNumber keys. Any light
 * userdata objects in the table are interpreted as pointers to objects. Any
 * keys or values whose types are not understood are silently omitted from the
 * result.
 *
 * @note In Lua, numeric indices are expected to start at one. The indices in
 * the table being popped off the stack are not adjusted in any way, so they may
 * begin at one instead of zero.
 *
 * @warning Light userdata is not retained by Lua. Retrieving it at a later time
 * may result in a reference to a deallocated object.
 */
+ (id)popFromStack:(MLCState *)state;

/**
 * Pushes the receiver on the Lua stack of \a state.
 *
 * Any keys or values that do not conform to the #MLCValue protocol are pushed
 * as light userdata.
 *
 * @warning Light userdata is not retained by Lua. Retrieving it at a later time
 * may result in a reference to a deallocated object.
 */
- (void)pushOntoStack:(MLCState *)state;
@end
