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
		if (![self validateValue:&value forKey:key error:&error]) {
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
