//
//  MLCValue.h
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 30.10.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>

@class MLCState;

/**
 * Represents a value type which can be passed to and from Lua.
 */
@protocol MLCValue <NSObject>
@required

/**
 * Returns whether a value of this type is at the top of the stack in the given
 * Lua state.
 */
+ (BOOL)isOnStack:(MLCState *)state;

/**
 * Attempts to create a value of this type from the top of the stack in the
 * given Lua state. Returns \c nil if an object of this type cannot be created
 * from the data at the top of the stack. Regardless of success or failure, the
 * topmost item on the stack of \a state is popped.
 */
+ (id)popFromStack:(MLCState *)state;

/**
 * Pushes the receiver onto the stack in the given Lua state.
 */
- (void)pushOntoStack:(MLCState *)state;
@end
