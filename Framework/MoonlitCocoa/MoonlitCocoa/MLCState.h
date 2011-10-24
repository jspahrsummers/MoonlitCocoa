//
//  MLCState.h
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 24.10.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>
#import <lua.h>

/**
 * Represents a Lua state.
 */
@interface MLCState : NSObject
/**
 * The state object managed by the receiver.
 */
@property (nonatomic, readonly) lua_State *state;

/**
 * Returns an autoreleased Lua state initialized with #init.
 */
+ (id)state;

/**
 * Initializes the receiver as a new Lua state with a completely unique
 * execution context.
 */
- (id)init;
@end
