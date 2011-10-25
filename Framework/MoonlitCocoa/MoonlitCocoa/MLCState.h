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
 * The name of an exception thrown if the Lua stack overflows.
 */
extern NSString * const MLCLuaStackOverflowException;

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
 * Pops \a argCount arguments from the top of the stack and calls the function
 * that should then be at the top. The number of results is adjusted to \a
 * resultCount upon return, unless \a resultCount is \c LUA_MULTRET. Upon
 * a successful call, \c YES is returned. If an error occurs, \c NO is returned,
 * and \a error (if provided) is filled in with information about the error.
 */
- (BOOL)callFunctionWithArgumentCount:(int)argCount resultCount:(int)resultCount error:(NSError **)error;

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

/**
 * Pops a string off the top of the Lua stack. The string is assumed to be
 * encoded with UTF-8. Returns \c nil if the value at the top of the Lua stack
 * is not a string or number.
 *
 * @note The string on the stack may contain embedded zeroes.
 */
- (NSString *)popString;

/**
 * Pushes \a str on the Lua stack.
 *
 * @note \a str is encoded with UTF-8 before being passed into Lua.
 */
- (void)pushString:(NSString *)str;
@end
