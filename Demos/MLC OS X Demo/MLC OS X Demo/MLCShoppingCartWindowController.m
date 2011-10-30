//
//  MLCShoppingCartWindowController.m
//  MLC OS X Demo
//
//  Created by Justin Spahr-Summers on 25.10.11.
//  Released into the public domain.
//

#import "MLCShoppingCartWindowController.h"

@implementation MLCShoppingCartWindowController
@synthesize shoppingCartView = m_shoppingCartView;

- (id)initWithWindow:(NSWindow *)window {
	return [super initWithWindowNibName:@"MLCShoppingCartWindow"];
}

#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  	return 0;
}

#pragma mark NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  	return nil;
}

@end
