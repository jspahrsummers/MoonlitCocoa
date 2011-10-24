//
//  MLCObject.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 23.10.11.
//  Released into the public domain.
//

#import "MLCObject.h"
#import "MLCState.h"

@interface MLCObject ()
@property (nonatomic, strong, readonly) MLCState *state;
@end

@implementation MLCObject
+ (NSURL *)implementationURL; {
	NSBundle *bundle = [NSBundle bundleForClass:self];
	NSString *className = NSStringFromClass(self);

	NSURL *URL = [bundle URLForResource:className withExtension:@"mlua"];
	if (URL)
		return URL;
	
	return [bundle URLForResource:className withExtension:@"lua"];
}

- (MLCState *)state {
  	static MLCState *classState = nil;
  	static dispatch_once_t pred;

	dispatch_once(&pred, ^{
		classState = [[MLCState alloc] init];

		NSString *source = [NSString stringWithContentsOfURL:[[self class] implementationURL] usedEncoding:NULL error:NULL];
		[classState loadString:source];
	});

	return classState;
}

- (id)init; {
	return [super init];
}

#pragma mark MLCValue

+ (BOOL)isInStack:(MLCState *)state atIndex:(int)index; {
	return NO;
}

+ (id)valueFromStack:(MLCState *)state atIndex:(int)index; {
	return nil;
}

- (void)pushOntoStack:(MLCState *)state; {
}
@end
