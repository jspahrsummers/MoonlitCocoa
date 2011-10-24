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
 * An error domain for error codes originating from Lua (i.e., codes with
 * symbolic names that begin with "LUA_").
 */
extern NSString * const MLCLuaErrorDomain;

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

/**
 * Loads the given Metalua script, pushing a function representing the script
 * onto the receiver's stack and returning \c YES upon success. If an error
 * occurs, \c NO is returned, and \a error (if provided) is filled in with
 * information about the error.
 */
- (BOOL)loadScript:(NSString *)source error:(NSError **)error;

/**
 * Loads the Metalua script at \a URL, pushing a function representing the
 * script onto the receiver's stack and returning \c YES upon success. If an
 * error occurs, \c NO is returned, and \a error (if provided) is filled in with
 * information about the error.
 */
- (BOOL)loadScriptAtURL:(NSURL *)URL error:(NSError **)error;
@end
