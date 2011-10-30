//
//  MLCAppDelegate.m
//  MLC OS X Demo
//
//  Created by Justin Spahr-Summers on 24.10.11.
//  Released into the public domain.
//

#import "MLCAppDelegate.h"
#import "MLCShoppingCartWindowController.h"

@interface MLCAppDelegate ()
@property (nonatomic, strong) NSMutableArray *windowControllers;
@end

@implementation MLCAppDelegate
@synthesize windowControllers = m_windowControllers;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  	self.windowControllers = [[NSMutableArray alloc] init];

  	NSWindowController *shoppingCartController = [[MLCShoppingCartWindowController alloc] init];
	[self.windowControllers addObject:shoppingCartController];
	[shoppingCartController showWindow:self];
}

@end
