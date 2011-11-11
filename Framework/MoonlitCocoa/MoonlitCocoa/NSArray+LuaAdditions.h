//
//  NSArray+LuaAdditions.h
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 10.11.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>
#import <MoonlitCocoa/MLCValue.h>

@interface NSArray (LuaAdditions)
/**
 * Returns \c YES if the value at the top of the Lua stack of \a state is
 * a table.
 *
 * @note This method does not verify that there are integral keys in the table.
 * This method will return \c YES even if the table at the top of the stack has
 * no array part.
 */
+ (BOOL)isOnStack:(MLCState *)state;

/**
 * Pops a table off the top of the Lua stack of \a state, returning its array
 * part. Returns \c nil if the value at the top of the Lua stack is not a table.
 *
 * Any non-numeric indices in the table are silently discarded. Any light
 * userdata objects in the table are interpreted as pointers to objects. Any
 * values whose types are not understood are inserted into the array as
 * instances of \c NSNull.
 *
 * @note In Lua, numeric indices are expected to start at one. This method will
 * subtract one from every index in the Lua table, resulting in an array that
 * begins at zero.
 *
 * @warning Light userdata is not retained by Lua. Retrieving it at a later time
 * may result in a reference to a deallocated object.
 */
+ (id)popFromStack:(MLCState *)state;

/**
 * Pushes the receiver on the Lua stack of \a state as a table.
 *
 * Any values that do not conform to the #MLCValue protocol are pushed as light
 * userdata.
 *
 * @note In Lua, numeric indices are expected to start at one. This method will
 * add one to every index in the receiver, resulting in a Lua table that begins
 * at one.
 *
 * @warning Light userdata is not retained by Lua. Retrieving it at a later time
 * may result in a reference to a deallocated object.
 */
- (void)pushOntoStack:(MLCState *)state;
@end
