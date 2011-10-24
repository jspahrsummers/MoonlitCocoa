//
//  MLCState.h
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 24.10.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>

/**
 * Represents a Lua state.
 */
@interface MLCState : NSObject
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
