//
//  MLCModel.h
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 30.10.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>
#import <MoonlitCocoa/MLCValue.h>
#import <MoonlitCocoa/MLCBridgedObject.h>

@lua_interface(MLCModel)
/**
 * The value associated with this key in Lua should be or return an array of the
 * key paths to be considered in an equality check, as performed by \c
 * -isEqual:.
 *
 * @note Because the implementation of \c -hash depends on the algorithm for
 * determining equality, the object's hash is also determined using the
 * specified key paths.
 */
- (NSSet *)keysForValuesAffectingEquality;
@end

/**
 * An abstract class representing an immutable model object bridged into Lua.
 * This class can be subclassed to get standard model object behaviors and Lua
 * bridging with minimal boilerplate.
 */
@interface MLCModel : MLCBridgedObject <MLCModel, NSCoding, NSCopying>
/**
 * Initializes the properties of the receiver using the keys and values in \a
 * dict.
 *
 * This is the designated initializer for this class. This method can be
 * overridden by subclasses to perform additional validation on the object after
 * calling the superclass implementation.
 */
- (id)initWithDictionary:(NSDictionary *)dict;

/**
 * Returns the properties of the receiver encoded in a dictionary.
 */
- (NSDictionary *)dictionaryValue;

/**
 * If the Lua metatable for the receiver has a key named \c hash, this method
 * returns that value (or the value returned by that function). Otherwise, this
 * returns a hash calculated from all of the values at
 * #keysForValuesAffectingEquality.
 */
- (NSUInteger)hash;

/**
 * If \a obj is not of the same class as the receiver, \c NO is returned. If the
 * Lua metatable for the receiver has a key named \c isEqual:, this method calls
 * that function and returns its result. Otherwise, this checks for equality of
 * all of the values at #keysForValuesAffectingEquality.
 */
- (BOOL)isEqual:(id)obj;

/**
 * Retrieves the Lua key by the same name, collecting the values of the table
 * into a set, for the purposes described in the Lua interface declaration of
 * this method.
 *
 * The default implementation of this method returns every property on the
 * receiver's class.
 */
- (NSSet *)keysForValuesAffectingEquality;
@end
