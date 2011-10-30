//
//  MLCShoppingCartWindowController.m
//  MLC OS X Demo
//
//  Created by Justin Spahr-Summers on 25.10.11.
//  Released into the public domain.
//

#import "MLCShoppingCartWindowController.h"
#import "MLCShoppingCart.h"
#import "MLCProduct.h"

@implementation MLCShoppingCartWindowController
@synthesize shoppingCartView = m_shoppingCartView;
@synthesize shoppingCart = m_shoppingCart;

- (NSString *)windowNibName {
  	return @"MLCShoppingCartWindow";
}

- (void)windowDidLoad {
  	NSArray *products = [NSArray arrayWithObjects:
		[[MLCProduct alloc] initWithName:@"Widget" price:[NSDecimalNumber decimalNumberWithString:@"2.50"]],
		[[MLCProduct alloc] initWithName:@"Thing" price:[NSDecimalNumber decimalNumberWithString:@"20.99"]],
		[[MLCProduct alloc] initWithName:@"Product" price:[NSDecimalNumber decimalNumberWithString:@"0.99"]],
		nil
	];

	self.shoppingCart = [[MLCShoppingCart alloc] initWithProducts:products];
	[self.shoppingCartView reloadData];
}

#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  	return (NSInteger)[self.shoppingCart.products count];
}

#pragma mark NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSString *identifier = [tableColumn identifier];
	MLCProduct *product = [self.shoppingCart.products objectAtIndex:(NSUInteger)row];

	NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
	cellView.textField.stringValue = [product valueForKey:identifier];
	return cellView;
}

@end
