//
//  MLCObject.h
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 23.10.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>
#import <MoonlitCocoa/MLCValue.h>

/**
 * An abstract class for a model object implemented in Lua.
 *
 * Every subclass of this class will have its own independent #MLCState isolated
 * from all others.
 */
@interface MLCObject : NSObject <MLCValue>
/**
 * A URL for the Lua implementation of this model object. Typically this will be
 * a file URL pointing to a Lua script in the application bundle. If this method
 * returns \c nil, the receiver cannot be instantiated.
 *
 * The default implementation of this method will search for a file named after
 * with the receiver's class with a \c .mlua or \c .lua extension (in that
 * order), returning whichever one is found, or \c nil if no matching file is
 * found.
 */
+ (NSURL *)implementationURL;

/**
 * Initializes the receiver as an empty object.
 */
- (id)init;
@end
