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

/**
 * An abstract class representing an immutable model object bridged into Lua.
 * This class can be subclassed to get standard model object behaviors and Lua
 * bridging with minimal boilerplate.
 */
@interface MLCModel : MLCBridgedObject <NSCoding, NSCopying>
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
@end
