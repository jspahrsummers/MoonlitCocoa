//
//  MLCModel.m
//  MoonlitCocoa
//
//  Created by Justin Spahr-Summers on 30.10.11.
//  Released into the public domain.
//

#import "MLCModel.h"
#import "MLCState.h"
#import "EXTRuntimeExtensions.h"
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
+ (NSArray *)modelPropertyNames;
@end

@implementation MLCModel

- (id)initWithDictionary:(NSDictionary *)dict; {
	self = [super init];
	if (!self)
		return nil;

	[self setValuesForKeysWithDictionary:dict];
	return self;
}

- (NSDictionary *)dictionaryValue; {
	NSArray *keys = [[self class] modelPropertyNames];
	return [self dictionaryWithValuesForKeys:keys];
}

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

+ (NSArray *)modelPropertyNames; {
	NSMutableArray *names = [[NSMutableArray alloc] init];

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

	// if Lua doesn't implement -hash, we hash our dictionary
	if (!num) {
		return [[self dictionaryValue] hash];
	} else {
		return [num unsignedIntegerValue];
	}
}

- (BOOL)isEqual:(MLCModel *)model {
	if (![model isKindOfClass:[self class]])
		return NO;
	
	// if Lua doesn't implement -isEqual:, we compare dictionary values
	if (![[self class] metatableHasValueForKey:@"isEqual:"]) {
		return [[self dictionaryValue] isEqual:[model dictionaryValue]];
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
