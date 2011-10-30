//
//  MLCShoppingCartWindowController.h
//  MLC OS X Demo
//
//  Created by Justin Spahr-Summers on 25.10.11.
//  Released into the public domain.
//

#import <Cocoa/Cocoa.h>

@interface MLCShoppingCartWindowController : NSWindowController
@property (nonatomic, weak) IBOutlet NSTableView *shoppingCartView;
@end
