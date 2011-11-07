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
 * Gets the value at \a index in the stack, attempting to create an Objective-C
 * object from its type. If no known mapping to Objective-C is known, \c nil is
 * returned.
 *
 * @note Strings are not converted in-place, making this safe for use with \c
 * lua_next.
 */
- (id)getValueAtStackIndex:(int)index;

/**
 * Attempts to ensure that \a size slots are free in the Lua stack. If not
 * enough slots are free and the stack cannot be grown, an
 * #MLCLuaStackOverflowException is thrown.
 */
- (void)growStackBySize:(int)size;

/**
 * Executes \a block, ensuring that the stack has expanded by \a delta slots
 * - or, if \a delta is negative, shrunk by \a delta slots - after the block has
 * completed.
 *
 * Returns the value returned by \a block.
 */
- (BOOL)enforceStackDelta:(int)delta forBlock:(BOOL (^)(void))block;

/**
 * Pops the value on the top of the stack, attempting to coerce it into a type
 * suitable for the return value of \a invocation. If any error occurs, the bits
 * of the return value are zeroed out and \c NO is returned.
 */
- (BOOL)popReturnValueForInvocation:(NSInvocation *)invocation;

/**
 * For a table at the top of the stack, replaces it with the value of \a field
 * obtained from that table.
 *
 * @note \a field may not contain embedded NULs.
 */
- (void)popTableAndPushField:(NSString *)field;

/**
 * For a table at the top of the stack, replaces it with its metatable.
 */
- (void)popTableAndPushMetatable;

/**
 * Pops the value on the top of the stack, attempting to create an Objective-C
 * object from its type. If no known mapping to Objective-C is known, \c nil is
 * returned.
 */
- (id)popValueOnStack;

/**
 * Pushes onto the stack a reference to the given global symbol.
 */
- (void)pushGlobal:(NSString *)symbol;

/**
 * If \a object conforms to the #MLCValue protocol, this invokes
 * MLCValue#pushOntoStack:. Otherwise, the object is pushed as light userdata.
 *
 * @warning Light userdata is not retained by Lua. Retrieving it at a later time
 * may result in a reference to a deallocated object.
 */
- (void)pushObject:(id)object;

/**
 * Pushes onto the stack the arguments stored in \a invocation, converting to
 * Lua types as appropriate. The target and the selector are not included in the
 * arguments pushed.
 */
- (void)pushArgumentsOfInvocation:(NSInvocation *)invocation;
@end
