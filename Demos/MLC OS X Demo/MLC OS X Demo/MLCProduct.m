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
@property (nonatomic, copy, readwrite) NSString *optionalString;
@end

@implementation MLCProduct
@synthesize name = m_name;
@synthesize price = m_price;
@synthesize optionalString = m_optionalString;

- (id)initWithName:(NSString *)name price:(NSDecimalNumber *)price; {
	return [self initWithName:name price:price optionalString:nil];
}

- (id)initWithName:(NSString *)name price:(NSDecimalNumber *)price optionalString:(NSString *)optionalString; {
  	NSParameterAssert(name != nil);
	NSParameterAssert(price != nil);

  	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		name, @"name",
		price, @"price",
		nil
	];

	if (optionalString)
		[dict setObject:optionalString forKey:@"optionalString"];

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
