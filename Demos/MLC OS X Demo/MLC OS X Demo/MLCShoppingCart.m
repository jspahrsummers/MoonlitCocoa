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

- (id)initWithProducts:(NSArray *)products; {
  	self = [super init];
	if (!self)
		return nil;
	
	if (!products)
		return nil;
	
	self.products = products;
	return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
  	return self;
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder {
  	NSArray *products = [coder decodeObjectForKey:@"products"];
  	return [self initWithProducts:products];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.products forKey:@"products"];
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
