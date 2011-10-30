//
//  MLCShoppingCart.m
//  MLC OS X Demo
//
//  Created by Justin Spahr-Summers on 25.10.11.
//  Released into the public domain.
//

#import "MLCShoppingCart.h"

@interface MLCShoppingCart ()
@property (nonatomic, copy, readwrite) NSArray *products;
@end

@implementation MLCShoppingCart
@synthesize products = m_products;

- (id)initWithDictionary:(NSDictionary *)dict; {
  	self = [super init];
	if (!self)
		return nil;
	
	[self setValuesForKeysWithDictionary:dict];

	if (!self.products)
		return nil;

	return self;
}

- (NSDictionary *)dictionaryValue; {
  	NSArray *keys = [NSArray arrayWithObject:@"products"];
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
  	return [self.products hash];
}

- (BOOL)isEqual:(MLCShoppingCart *)obj {
  	if (![obj isKindOfClass:[MLCShoppingCart class]])
		return NO;
	
	return [self.products isEqualToArray:obj.products];
}

@end
