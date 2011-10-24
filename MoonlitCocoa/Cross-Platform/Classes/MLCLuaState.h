//
//  MLCLuaState.h
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 23.10.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>
#import <lua.h>

/**
 * Represents a Lua state, which is a thread in a Lua execution context.
 * Multiple Lua state objects may share the same global state, if some are
 * threads created from one original.
 */
@interface MLCLuaState : NSObject
/**
 * The Lua state object owned by the receiver.
 */
@property (nonatomic, readonly) lua_State *state;

/**
 * Initializes the receiver as a new Lua state, using the default allocator.
 * Once the state has been initialized, all standard Lua libraries are
 * automatically loaded.
 */
- (id)init;

/**
 * Initializes the receiver with the given Lua state object. If \a closeWhenDone
 * is \c YES, the state object is closed when the receiver is deallocated.
 *
 * This is the designated initializer for this class.
 */
- (id)initWithState:(lua_State *)state closeWhenDone:(BOOL)closeWhenDone;
@end
