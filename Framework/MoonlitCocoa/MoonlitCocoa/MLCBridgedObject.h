//
//  MLCBridgedObject.h
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 04.11.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>

/**
 * Declares, in a protocol \a NAME, methods that will be implemented in Lua. An
 * object bridged into Lua can then conform to protocol \a NAME to indicate its
 * ability to invoke those Lua methods.
 */
#define lua_interface(NAME) \
	protocol NAME <NSObject> \
	@optional

@end
