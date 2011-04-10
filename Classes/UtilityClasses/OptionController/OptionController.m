//
//  OptionController.m
//  MacHg
//
//  Created by Jason Harris on 1/20/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "OptionController.h"
#import "MacHgDocument.h"

@implementation OptionController

@synthesize specialHandling;
@synthesize originalTarget;
@synthesize originalAction;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) setName:(NSString*)name
{
	optionName = name;
}

-(void) awakeFromNib
{
	[self setOriginalTarget:[optionSwitchButton target]];
	[self setOriginalAction:[optionSwitchButton action]];
	[optionSwitchButton setAction:@selector(setOptionValueStateFromButton:)];
	[optionSwitchButton setTarget:self];
	[optionSwitchButton setContinuous:YES];
	[optionValueField   setContinuous:YES];
	specialHandling = NO;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Accessors and Setters
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)      optionIsSet								{ return ([optionSwitchButton state] == NSOnState); }
- (NSString*) optionValue								{ return [self optionIsSet] ? [optionValueField stringValue] : nil; }
- (void)	  setOptionValue:(NSString*)value			{ [optionValueField setStringValue:nonNil(value)]; [self setOverallState:value?YES:NO]; }

- (IBAction)  setOptionValueStateFromButton:(id)sender
{
	[self setOverallState:([optionSwitchButton state] == NSOnState)];
	[optionSwitchButton sendAction:originalAction to:originalTarget];
}

- (void) setOverallState:(BOOL)state
{
	if (state == YES)
	{
		[optionSwitchButton setState:NSOnState];
		[optionValueField setAlphaValue:0.0];
		[optionValueField setHidden:NO];
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.2];
		[[optionValueField animator] setAlphaValue:1.0];
		[NSAnimationContext endGrouping];
		[optionValueField setSelectable:YES];
		[optionValueField setEditable:YES];
	}
	else
	{
		[optionSwitchButton setState:NSOffState];
		[optionValueField setSelectable:NO];
		[optionValueField setEditable:NO];
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.2];
		[[optionValueField animator] setAlphaValue:0.0];
		[NSAnimationContext endGrouping];
		[optionValueField performSelector:@selector(setHidden:) withObject:YESasNumber afterDelay:0.2];
		NSWindow* parentWindow = [optionValueField window];
		[parentWindow performSelector:@selector(makeFirstResponder:) withObject:parentWindow afterDelay:0.2];
	}
}

- (void) addOptionToArgs:(NSMutableArray*)args
{
	if (specialHandling || ![self optionIsSet])
		return;
	[args addObject:fstr(@"--%@", optionName)];
	if (optionValueField)
		[args addObject:[self optionValue]];
}

+ (BOOL) containsOptionWhichIsSet:(NSArray*)options
{
	for (id obj in options)
		if ([obj respondsToSelector:@selector(optionIsSet)])
			if ([obj optionIsSet])
				return YES;
	return NO;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Connections
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) setConnections:(NSMutableDictionary*)connections fromOptionWithKey:(NSString*)key
{
	NSString* fullKey = [key stringByAppendingString:optionName];
	if ([self optionIsSet])
	{
		id value;
		if (optionValueField)
			value = [self optionValue];
		else
			value = YESasNumber;
		[connections setObject:value forKey:fullKey];
	}
	else
		[connections removeObjectForKey:fullKey];
}

- (void) setOptionFromConnections:(NSMutableDictionary*)connections forKey:(NSString*)key
{
	NSString* fullKey = [key stringByAppendingString:optionName];
	id val = [connections objectForKey:fullKey];
	[self setOptionValue:val];
}

+ (void) setOptions:(NSArray*)options  fromConnections:(NSMutableDictionary*)connections  forKey:(NSString*)key
{
	for (OptionController* opt in options)
		[opt setOptionFromConnections:connections forKey:key];
}

+ (void) setConnections:(NSMutableDictionary*)connections  fromOptions:(NSArray*)options  forKey:(NSString*)key
{
	for (OptionController* opt in options)
		[opt setConnections:connections fromOptionWithKey:key];
}



@end
