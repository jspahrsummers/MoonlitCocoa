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

- (BOOL)validateName:(NSString **)name error:(NSError **)error {
	return [*name length] > 0;
}

- (BOOL)validatePrice:(NSDecimalNumber **)price error:(NSError **)error {
  	// pass validation if the price is greater than or equal to zero
	return [*price compare:[NSDecimalNumber zero]] != NSOrderedAscending;
}

@end
