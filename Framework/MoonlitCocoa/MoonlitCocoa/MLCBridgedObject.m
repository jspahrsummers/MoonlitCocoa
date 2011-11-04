//
//  MLCBridgedObject.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 04.11.11.
//  Released into the public domain.
//

#import "MLCBridgedObject.h"

@implementation MLCBridgedObject
+ (id)objectFromUserdata:(void *)userdata transferringOwnership:(BOOL)transfer; {
	void **userdataContainingPtr = userdata;

	id obj = nil;
	
	if (transfer) {
		obj = (__bridge_transfer id)*userdataContainingPtr;
	} else {
		obj = (__bridge id)*userdataContainingPtr;
	}

	if ([obj isKindOfClass:self])
		return obj;
	else
		return nil;
}

@end
