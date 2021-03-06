//
//  MLCProduct.h
//  MLC OS X Demo
//
//  Created by Justin Spahr-Summers on 25.10.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>
#import <MoonlitCocoa/MoonlitCocoa.h>

/**
 * An immutable product model object.
 */
@lua_bridged(MLCProduct, MLCModel)
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSDecimalNumber *price;
@property (nonatomic, copy, readonly) NSString *optionalString;
@property (nonatomic, copy, readonly) NSString *formattedPrice;

- (id)initWithName:(NSString *)name price:(NSDecimalNumber *)price;
- (id)initWithName:(NSString *)name price:(NSDecimalNumber *)price optionalString:(NSString *)optionalString;

- (void)printFormattedPrice;
@end
