//
//  MLCBridgedObject.h
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 04.11.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>
#import <MoonlitCocoa/MLCValue.h>
#import <lua.h>

@class MLCState;

/**
 * Declares, in a protocol \a NAME, methods that will be implemented in Lua. An
 * object bridged into Lua can then conform to protocol \a NAME to indicate its
 * ability to invoke those Lua methods.
 */
#define lua_interface(NAME) \
	protocol NAME <NSObject> \
	@optional

/**
 * An abstract class representing an Objective-C object that can be bridged as
 * full userdata into Lua. Any messages sent to an instance of this class that
 * it does not understand will be automatically forwarded to its Lua
 * implementation.
 */
@interface MLCBridgedObject : NSObject <MLCValue>
/**
 * Returns the #MLCState object for this class. If no Lua state has yet been set
 * up, this will create one and attempt to load a Lua script with the name of
 * the current class and a .mlua or .lua extension.
 */
+ (MLCState *)state;

/**
 * The \c __gc metamethod for instances of the receiver.
 *
 * The default implementation of this function gets the object associated with
 * one userdata argument, then transfers ownership of that object to ARC,
 * effectively decrementing its retain count.
 */
+ (lua_CFunction)gcMetamethod;

/**
 * The \c __index metamethod for instances of the receiver.
 *
 * The default implementation of this function returns a trampoline to invoke
 * a method by the specified name on the specific instance of the receiver.
 */
+ (lua_CFunction)indexMetamethod;

/**
 * The \c __eq metamethod for instances of the receiver.
 *
 * The default implementation of this function gets the objects associated with
 * two userdata arguments, then compares them with \c -isEqual:.
 */
+ (lua_CFunction)eqMetamethod;

/**
 * Returns \c YES if \a aSelector is implemented by instances of the receiver,
 * either in Cocoa or in Lua.
 *
 * @note This may return \c YES for a key which is associated with a primitive
 * value in Lua, where using key-value coding to obtain that key would succeed,
 * but attempting to invoke that key as a method would fail.
 */
+ (BOOL)instancesRespondToSelector:(SEL)aSelector;

/**
 * Uses the selector of \a invocation as a key into the Lua table backing the
 * receiver, invoking the function associated with that key using the arguments
 * from \a invocation (after converting to the appropriate Lua types). If the
 * invocation's method signature dictates a return value, the first return value
 * from the function is used; zero is returned if the function has no return
 * values.
 */
- (void)forwardInvocation:(NSInvocation *)invocation;

/**
 * Returns \c YES if the metatable of the receiver has a value associated with
 * \a key.
 */
+ (BOOL)metatableHasValueForKey:(NSString *)key;

/**
 * Uses \a key into the Lua table backing the receiver. If \a key is associated
 * with a non-nil value compatible with Objective-C, that value is returned. If
 * \a key is associated with a function, the function is invoked with \c self
 * and \c _cmd arguments, and the return value from that function is returned.
 * For any other cases, an \c NSUndefinedKeyException is raised.
 */
- (id)valueForUndefinedKey:(NSString *)key;

/**
 * Returns the instance of the receiver corresponding to \a userdata, or \c nil
 * if \a userdata is invalid or does not contain an instance of the receiver.
 *
 * If \a transfer is \c YES, ownership is transferred to ARC (effectively
 * decrementing the object's retain count).
 *
 * @note If an object is associated with \a userdata, but is not an instance of
 * the receiver, and \a transfer is \c YES, ownership of that object is still
 * transferred to ARC, and \c nil is returned.
 */
+ (id)objectFromUserdata:(void *)userdata transferringOwnership:(BOOL)transfer;

/**
 * Pushes onto the #state the metatable object meant for the receiver's
 * userdata.
 */
+ (void)pushUserdataMetatable;
@end
