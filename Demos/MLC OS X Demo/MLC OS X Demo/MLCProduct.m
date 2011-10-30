//
//  MLCProduct.m
//  MLC OS X Demo
//
//  Created by Justin Spahr-Summers on 25.10.11.
//  Released into the public domain.
//

#import "MLCProduct.h"

@interface MLCProduct ()
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSDecimalNumber *price;
@end

@implementation MLCProduct
@synthesize name = m_name;
@synthesize price = m_price;

- (id)initWithName:(NSString *)name price:(NSDecimalNumber *)price; {
  	NSParameterAssert(name != nil);
	NSParameterAssert(price != nil);

  	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
		name, @"name",
		price, @"price",
		nil
	];

	return [self initWithDictionary:dict];
}

- (id)initWithDictionary:(NSDictionary *)dict; {
  	self = [super init];
	if (!self)
		return nil;

	[self setValuesForKeysWithDictionary:dict];
	
	if (![self.name length])
		return nil;
	
	// if the price is less than zero
	if ([self.price compare:[NSDecimalNumber zero]] == NSOrderedAscending)
		return nil;
	
	return self;
}

- (NSDictionary *)dictionaryValue; {
  	NSArray *keys = [NSArray arrayWithObjects:@"name", @"price", nil];
  	return [self dictionaryWithValuesForKeys:keys];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
  	return self;
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder {
  	NSDictionary *dict = [coder decodeObjectForKey:@"dictionaryValue"];
  	return [self initWithDictionary:dict];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:[self dictionaryValue] forKey:@"dictionaryValue"];
}

#pragma mark NSObject

- (NSUInteger)hash {
  	return [self.name hash];
}

- (BOOL)isEqual:(MLCProduct *)obj {
  	if (![obj isKindOfClass:[MLCProduct class]])
		return NO;

	return [self.name isEqualToString:obj.name] && [self.price isEqual:obj.price];
}

@end
