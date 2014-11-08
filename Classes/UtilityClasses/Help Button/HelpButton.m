//
//  TitledButton.m
//  MacHg
//
//  Created by Jason Harris on 3/12/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "HelpButton.h"
#import "Common.h"

@implementation HelpButton

@synthesize helpAnchorName = helpAnchorName_;

- (void) awakeFromNib
{
	[self setAction:@selector(openHelpAnchor:)];
	weakSelf = self;
	[self setTarget:weakSelf];
}

- (void) openHelpAnchor:(id)sender
{
	NSString* locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:self.helpAnchorName inBook:locBookName];
}
	 
@end
