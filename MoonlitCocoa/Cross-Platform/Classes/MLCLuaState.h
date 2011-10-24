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
 * The paths to search for Lua libraries, as previously set with #setLuaPaths:.
 * If #setLuaPaths: was never called, this returns \c nil.
 */
+ (NSArray *)luaPaths;

/**
 * Sets the paths to search for Lua libraries. The specified paths are appended
 * to the default path. Any \c ? in a path is replaced with the name of the file
 * being searched for.
 *
 * This only affects MLCLuaState objects created after the call to this method.
 */
+ (void)setLuaPaths:(NSArray *)paths;

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

/**
 * Attempts to compile and load \a source, which can be Metalua or Lua source.
 * If there are no errors, the compiled chunk is pushed as a Lua function on top
 * of the stack and \c YES is returned. Otherwise, an error message is pushed,
 * and \c NO is returned.
 */
- (BOOL)loadString:(NSString *)source;
@end
