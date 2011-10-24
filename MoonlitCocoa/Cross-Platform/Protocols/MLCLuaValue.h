//
//  MLCLuaValue.h
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 23.10.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>

@class MLCState;

/**
 * An object that can be converted to and from a valid Lua value.
 */
@protocol MLCLuaValue <NSObject>
@required
/**
 * Returns whether the value at \a index in the stack of the given Lua state is
 * compatible with the receiver. If \c YES is returned, you can create an
 * instance of the receiver from the same stack index.
 */
+ (BOOL)isInStack:(MLCState *)state atIndex:(int)index;

/**
 * Returns the value at \a index in the stack of the given Lua state, or \c nil
 * if the value at the index cannot be converted to an instance of the receiver.
 */
+ (id)valueFromStack:(MLCState *)state atIndex:(int)index;

/**
 * Pushes the receiver onto the top of the stack of the given Lua state.
 */
- (void)pushOntoStack:(MLCState *)state;
@end
