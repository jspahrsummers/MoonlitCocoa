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
  	self = [super init];
	if (!self)
		return nil;
	
	if (![name length])
		return nil;
	
	// if the price is less than zero
	if ([price compare:[NSDecimalNumber zero]] == NSOrderedAscending)
		return nil;
	
	self.name = name;
	self.price = price;
	return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
  	return self;
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder {
  	NSString *name = [coder decodeObjectForKey:@"name"];
	NSDecimalNumber *price = [coder decodeObjectForKey:@"price"];
	return [self initWithName:name price:price];
}

- (void)encodeWithCoder:(NSCoder *)coder {
  	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.price forKey:@"price"];
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
