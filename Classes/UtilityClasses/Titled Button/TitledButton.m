//
//  TitledButton.m
//  MacHg
//
//  Created by Jason Harris on 3/12/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "TitledButton.h"
#import "Common.h"

@implementation TitledButton

- (NSAttributedString*) determineDecoratedTitle
{
	NSMutableParagraphStyle* ps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[ps setAlignment:NSCenterTextAlignment];
	NSUInteger mask = [self keyEquivalentModifierMask];
	NSMutableString* modifiers = [[NSMutableString alloc] init];
	if (mask & NSControlKeyMask)	[modifiers appendString:@"⌃"];
	if (mask & NSAlternateKeyMask)	[modifiers appendString:@"⌥"];
	if (mask & NSCommandKeyMask)	[modifiers appendString:@"⌘"];
	
	NSString* key   = [[self keyEquivalent] uppercaseString];
	NSFont* keyFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	
	NSDictionary* standardAttributes = @{NSFontAttributeName: keyFont, NSParagraphStyleAttributeName: ps};
	NSDictionary* grayedAttributes   = @{NSFontAttributeName: keyFont, NSForegroundColorAttributeName: [NSColor colorWithDeviceHue:0.0 saturation:0.0 brightness:0.8 alpha:1.0], NSParagraphStyleAttributeName: ps};
	NSMutableAttributedString* constructDecoratedTitle = [NSMutableAttributedString string:originalTitle withAttributes:standardAttributes];
	[constructDecoratedTitle appendAttributedString: [NSAttributedString string:fstr(@" %@%@", modifiers, key) withAttributes:grayedAttributes]];
	return constructDecoratedTitle;
}

- (void) switchToDecoratedTitle	{ [self setAttributedTitle:decoratedTitle]; }
- (void) switchToStandardTitle	{ [self setTitle:originalTitle]; }

- (void) awakeFromNib
{
	originalTitle  = [self title];
	decoratedTitle = [self determineDecoratedTitle];
	[self observe:kCommandKeyIsDown		from:nil  byCalling:@selector(switchToDecoratedTitle)];
	[self observe:kCommandKeyIsUp		from:nil  byCalling:@selector(switchToStandardTitle)];

	// Set Initial state correctly.
	CGEventRef event = CGEventCreate(NULL /*default event source*/);
	CGEventFlags modifiers = CGEventGetFlags(event);
	CFRelease(event);

	BOOL isCommandDown  = bitsInCommon(modifiers, kCGEventFlagMaskCommand);
	if (isCommandDown)
		[self switchToDecoratedTitle];
	else
		[self switchToStandardTitle];
	
}


@end
