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
 * Keys and values in the table are retrieved according to the semantics of
 * MLCState#popValueOnStack. Any keys or values whose types are not understood
 * are silently omitted from the returned dictionary.
 *
 * @note In Lua, numeric indices are expected to start at one. The indices in
 * the table being popped off the stack are not adjusted in any way, so they may
 * begin at one instead of zero.
 */
+ (id)popFromStack:(MLCState *)state;

/**
 * Pushes the receiver on the Lua stack of \a state. All keys and values are
 * converted to Lua types according to the semantics of MLCState#pushObject:.
 */
- (void)pushOntoStack:(MLCState *)state;
@end
