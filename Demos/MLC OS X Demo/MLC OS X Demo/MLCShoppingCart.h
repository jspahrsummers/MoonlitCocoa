//
//  MLCShoppingCart.h
//  MLC OS X Demo
//
//  Created by Justin Spahr-Summers on 25.10.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>

/**
 * An immutable shopping cart model object.
 */
@interface MLCShoppingCart : NSObject <NSCoding, NSCopying>
@property (nonatomic, copy, readonly) NSArray *products;

- (id)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryValue;
@end
