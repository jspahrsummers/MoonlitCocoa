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
  	self = [super initWithDictionary:dict];
	if (!self)
		return nil;
	
	if (![self.name length])
		return nil;
	
	// if the price is less than zero
	if ([self.price compare:[NSDecimalNumber zero]] == NSOrderedAscending)
		return nil;
	
	return self;
}

@end
