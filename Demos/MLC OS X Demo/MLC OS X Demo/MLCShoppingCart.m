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
  	self = [super initWithDictionary:dict];
	if (!self)
		return nil;

	if (!self.products)
		return nil;

	return self;
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
