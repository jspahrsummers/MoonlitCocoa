//
//  MLCProduct.h
//  MLC OS X Demo
//
//  Created by Justin Spahr-Summers on 25.10.11.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>

/**
 * An immutable product model object.
 */
@interface MLCProduct : NSObject <NSCoding, NSCopying>
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSDecimalNumber *price;

- (id)initWithName:(NSString *)name price:(NSDecimalNumber *)price;
@end
