//
//  MLCModel.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 30.10.11.
//  Released into the public domain.
//

#import "MLCModel.h"
#import "MLCState.h"
#import <lauxlib.h>
#import <objc/runtime.h>

@interface MLCModel ()
/**
 * Enumerates all the properties of the receiver and any superclasses, up until
 * the MLCModel class.
 */
+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property))block;

/**
 * Returns an array containing the names of all the model properties of the
 * receiver and any superclasses, up until the MLCModel class.
 */
+ (NSSet *)modelPropertyNames;

/**
 * Returns a dictionary containing the values on the receiver that are
 * associated with each of the #keysForValuesAffectingEquality.
 */
- (NSDictionary *)dictionaryWithValuesAffectingEquality;
@end

@implementation MLCModel

- (id)init {
	return [self initWithDictionary:[NSDictionary dictionary]];
}

- (id)initWithDictionary:(NSDictionary *)dict; {
	self = [super init];
	if (!self)
		return nil;
	
	for (NSString *key in dict) {
		id value = [dict objectForKey:key];

		// match the convention used by -setValuesForKeysWithDictionary:
		if ([value isEqual:[NSNull null]])
			value = nil;

		NSError *error = nil;
		BOOL success = NO;

		@try {
			success = [self validateValue:&value forKey:key error:&error];
		} @catch (NSException *ex) {
			NSLog(@"Exception thrown during validation for key \"%@\" when initializing instance of %@: %@", key, [self class], ex);
			return nil;
		}

		if (!success) {
			NSLog(@"Validation failed for key \"%@\" when initializing instance of %@: %@", key, [self class], error);
			return nil;
		}

		[self setValue:value forKey:key];
	}

	return self;
}

- (NSDictionary *)dictionaryValue; {
	NSSet *keys = [[self class] modelPropertyNames];
	return [self dictionaryWithValuesForKeys:[keys allObjects]];
}

- (NSSet *)keysForValuesAffectingEquality; {
	NSString *key = NSStringFromSelector(_cmd);

	NSSet *keyPaths = nil;
	if ([[self class] metatableHasValueForKey:key]) {
		id value = [self valueForUndefinedKey:key];

		// only accept dictionaries, since any other type is not a Lua table
		if ([value isKindOfClass:[NSDictionary class]]) {
			keyPaths = value;
		}
	}

	if (!keyPaths) {
		// fall back to all properties if nothing else is available
		keyPaths = [[self class] modelPropertyNames];
	}
	
	return keyPaths;
}

- (NSDictionary *)dictionaryWithValuesAffectingEquality; {
	NSSet *equalityKeyPaths = [self keysForValuesAffectingEquality];
	return [self dictionaryWithValuesForKeys:[equalityKeyPaths allObjects]];
}

#pragma mark Magic

+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property))block; {
	for (Class cls = self;cls != [MLCModel class];cls = [cls superclass]) {
		unsigned count = 0;
		objc_property_t *properties = class_copyPropertyList(cls, &count);

		if (!properties)
			continue;

		for (unsigned i = 0;i < count;++i) {
			block(properties[i]);
		}

		free(properties);
	}
}

+ (NSSet *)modelPropertyNames; {
	NSMutableSet *names = [[NSMutableSet alloc] init];

	[self enumeratePropertiesUsingBlock:^(objc_property_t property){
		const char *cName = property_getName(property);
		NSString *str = [[NSString alloc] initWithUTF8String:cName];

		[names addObject:str];
	}];

	return names;
}

+ (BOOL)resolveInstanceMethod:(SEL)aSelector {
	@autoreleasepool {
		NSString *name = NSStringFromSelector(aSelector);
		NSRange range = [name rangeOfString:@":" options:NSLiteralSearch];

		// if the name doesn't match a standard init method, or there's no colon
		// (meaning no argument), or the colon immediately follows "initWith",
		// we can't build this
		if (![name hasPrefix:@"initWith"] || range.location == NSNotFound || range.location == 8)
			return NO;

		NSMutableString *firstPropertyName = [[NSMutableString alloc] init];
		
		// grab the letter after 'initWith' and lowercase it
		[firstPropertyName appendString:[[name substringWithRange:NSMakeRange(8, 1)] lowercaseString]];
		
		// append the rest, up to the first colon
		[firstPropertyName appendString:[name substringWithRange:NSMakeRange(9, range.location - 9)]];

		NSAssert([firstPropertyName length] > 0, @"name of first initializer argument should have a non-zero length");
		
		NSMutableArray *initializerPropertyNames = [[NSMutableArray alloc] init];
		[initializerPropertyNames addObject:firstPropertyName];

		// if the colon wasn't the last character in the initializer name, there
		// are must be properties named
		if (range.location < [name length] - 1) {
			NSArray *otherPropertyNames = [[name substringFromIndex:range.location + 1] componentsSeparatedByString:@":"];
			NSAssert([otherPropertyNames count] > 0, @"should be at least one other initializer argument if the first colon wasn't the last character in the method name");

			[initializerPropertyNames addObjectsFromArray:otherPropertyNames];

			NSAssert([[initializerPropertyNames lastObject] isEqualToString:@""], @"last colon-separated component of a method name with arguments should be an empty string");
			[initializerPropertyNames removeLastObject];
		}

		id (^finalInitializerBlock)(id, NSArray *) = ^(id self, NSArray *arguments){
			NSUInteger argumentCount = [arguments count];
			NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:argumentCount];

			for (NSUInteger i = 0;i < argumentCount;++i) {
				id argument = [arguments objectAtIndex:i];
				NSString *key = [initializerPropertyNames objectAtIndex:i];

				[dict setObject:argument forKey:key];
			}

			return [self initWithDictionary:dict];
		};

		id initializerBlock = nil;
		NSUInteger numberOfArguments = [initializerPropertyNames count];

		// UGH!
		switch (numberOfArguments) {
		case 1:
			{
				initializerBlock = [^(id self, id arg1){
					return finalInitializerBlock(self, [NSArray arrayWithObjects:arg1, nil]);
				} copy];

				break;
			}

		case 2:
			{
				initializerBlock = [^(id self, id arg1, id arg2){
					return finalInitializerBlock(self, [NSArray arrayWithObjects:arg1, arg2, nil]);
				} copy];

				break;
			}

		case 3:
			{
				initializerBlock = [^(id self, id arg1, id arg2, id arg3){
					return finalInitializerBlock(self, [NSArray arrayWithObjects:arg1, arg2, arg3, nil]);
				} copy];

				break;
			}
		
		case 4:
			{
				initializerBlock = [^(id self, id arg1, id arg2, id arg3, id arg4){
					return finalInitializerBlock(self, [NSArray arrayWithObjects:arg1, arg2, arg3, arg4, nil]);
				} copy];

				break;
			}
		
		case 5:
			{
				initializerBlock = [^(id self, id arg1, id arg2, id arg3, id arg4, id arg5){
					return finalInitializerBlock(self, [NSArray arrayWithObjects:arg1, arg2, arg3, arg4, arg5, nil]);
				} copy];

				break;
			}
		
		case 6:
			{
				initializerBlock = [^(id self, id arg1, id arg2, id arg3, id arg4, id arg5, id arg6){
					return finalInitializerBlock(self, [NSArray arrayWithObjects:arg1, arg2, arg3, arg4, arg5, arg6, nil]);
				} copy];

				break;
			}
			
		case 7:
			{
				initializerBlock = [^(id self, id arg1, id arg2, id arg3, id arg4, id arg5, id arg6, id arg7){
					return finalInitializerBlock(self, [NSArray arrayWithObjects:arg1, arg2, arg3, arg4, arg5, arg6, arg7, nil]);
				} copy];

				break;
			}
		
		case 8:
			{
				initializerBlock = [^(id self, id arg1, id arg2, id arg3, id arg4, id arg5, id arg6, id arg7, id arg8){
					return finalInitializerBlock(self, [NSArray arrayWithObjects:arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, nil]);
				} copy];

				break;
			}
		
		case 9:
			{
				initializerBlock = [^(id self, id arg1, id arg2, id arg3, id arg4, id arg5, id arg6, id arg7, id arg8, id arg9){
					return finalInitializerBlock(self, [NSArray arrayWithObjects:arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, nil]);
				} copy];

				break;
			}

		default:
			return NO;
		}

		NSMutableString *typeEncoding = [[NSMutableString alloc] init];

		// id impl (id self, SEL _cmd, ...)
		[typeEncoding appendFormat:@"%s%s%s", @encode(id), @encode(id), @encode(SEL)];

		// add each 'id' argument to the type encoding
		for (NSUInteger i = 0;i < numberOfArguments;++i) {
			[typeEncoding appendFormat:@"%s", @encode(id)];
		}

		if (class_addMethod(self, aSelector, imp_implementationWithBlock((__bridge void *)initializerBlock), [typeEncoding UTF8String])) {
			objc_setAssociatedObject(self, aSelector, initializerBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
		}

		return YES;
	}
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder {
	NSDictionary *dict = [coder decodeObjectForKey:@"dictionaryValue"];
	return [self initWithDictionary:dict];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	NSDictionary *dict = [self dictionaryValue];
	if (dict)
		[coder encodeObject:dict forKey:@"dictionaryValue"];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

#pragma mark NSObject

- (NSUInteger)hash {
	NSNumber *num = nil;

	if ([[self class] metatableHasValueForKey:@"hash"]) {
		id obj = [self valueForUndefinedKey:@"hash"];

		if ([obj isKindOfClass:[NSNumber class]]) {
			num = obj;
		} else if ([obj isKindOfClass:[NSString class]]) {
			num = [NSNumber numberWithDouble:[obj doubleValue]];
		}
	}

	// if Lua doesn't implement -hash, we hash our equality key paths
	if (!num) {
		return [[self dictionaryWithValuesAffectingEquality] hash];
	} else {
		return [num unsignedIntegerValue];
	}
}

- (BOOL)isEqual:(MLCModel *)model {
	if (![model isKindOfClass:[self class]])
		return NO;
	
	// if Lua doesn't implement -isEqual:, we compare our equality key paths
	if (![[self class] metatableHasValueForKey:@"isEqual:"]) {
		NSDictionary *selfEqualityValues = [self dictionaryWithValuesAffectingEquality];
		NSDictionary *otherEqualityValues = [model dictionaryWithValuesAffectingEquality];
		return [selfEqualityValues isEqualToDictionary:otherEqualityValues];
	}
	
	NSMethodSignature *signature = [self methodSignatureForSelector:_cmd];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];

	[invocation setTarget:self];
	[invocation setSelector:_cmd];

	[invocation setArgument:&model atIndex:2];
	[self forwardInvocation:invocation];

	BOOL result = NO;
	[invocation getReturnValue:&result];

	return result;
}

@end
