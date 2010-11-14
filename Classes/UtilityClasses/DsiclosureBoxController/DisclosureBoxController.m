//
//  DisclosureBoxController.m
//  MacHg
//
//  Created by Jason Harris on 22/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "DisclosureBoxController.h"


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  DisclosureBoxController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation DisclosureBoxController

- (void) awakeFromNib
{
	NSString* frameName  = [parentWindow frameAutosaveName];
	NSRect frameRect     = [parentWindow frame];
	autoSaveName_        = IsNotEmpty(frameName) ? fstr(@"%@:disclosed", frameName) : nil;
	BOOL disclosed       = autoSaveName_ ? [[NSUserDefaults standardUserDefaults] boolForKey:autoSaveName_] : NO;

	[self setToOpenState:disclosed];
	if (!disclosed && autoSaveName_)
		[parentWindow setFrame:frameRect display:NO animate:NO];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Resizing control
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) saveAutosizingMasksAndRelativePositions
{
	if (!savedViewsInfo)
	{
		NSMapTable* masks = [NSMapTable mapTableWithWeakToStrongObjects];
		NSRect discloseRect = [disclosureBox frame];
		NSArray* viewsInWindow = [[parentWindow contentView] subviews];
		for (NSView* view in viewsInWindow)
		{
			ViewPosition position = (NSMaxY([view frame]) > NSMaxY(discloseRect)) ? eViewAboveDisclosure : eViewBelowDisclosure;
			SavedViewInfo* info = [SavedViewInfo savedViewInfoWithMask:[view autoresizingMask] position:position];
			[masks setObject:info forKey:view];
		}
		savedViewsInfo = masks;
	}
}

- (void) setAutosizingMasksForDisclose
{	
	for (NSView* view in savedViewsInfo)
	{
		SavedViewInfo* info = DynamicCast(SavedViewInfo,[savedViewsInfo objectForKey:view]);
		if ([info position] == eViewAboveDisclosure)
			[view setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
		else
			[view setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
	};
}

- (void) restoreAutosizingMasks
{
	for (NSView* view in savedViewsInfo)
	{
		SavedViewInfo* info = DynamicCast(SavedViewInfo,[savedViewsInfo objectForKey:view]);
		[view setAutoresizingMask:[info mask]];
	};
}


- (CGFloat) sizeChange	{ return [disclosureBox frame].size.height + 5; } 		// The extra +5 accounts for the space between the box and its neighboring views





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) disclosureTrianglePressed:(id)sender	{ [self syncronizeDisclosureBoxToButtonStateWithAnimation:YES]; }

- (IBAction) ensureDisclosureBoxIsOpen:(id)sender
{
	[disclosureButton setState:NSOnState];
	[self syncronizeDisclosureBoxToButtonStateWithAnimation:NO];
}


- (IBAction) ensureDisclosureBoxIsClosed:(id)sender
{
	[disclosureButton setState:NSOffState];
	[self syncronizeDisclosureBoxToButtonStateWithAnimation:NO];
}


- (void) setToOpenState:(BOOL)state
{
	if (state == YES)
		[self ensureDisclosureBoxIsOpen:self];
	else if (state == NO)
		[self ensureDisclosureBoxIsClosed:self];
}


- (void) syncronizeDisclosureBoxToButtonStateWithAnimation:(BOOL)animate
{
	[self saveAutosizingMasksAndRelativePositions];
	if (autoSaveName_)
		[[NSUserDefaults standardUserDefaults] setBool:([disclosureButton state] == NSOnState) forKey:autoSaveName_];
	
	NSRect windowFrame = [parentWindow frame];
	CGFloat sizeChange = [self sizeChange];

	NSTimeInterval resizeTime = [parentWindow animationResizeTime:windowFrame];
	[self setAutosizingMasksForDisclose];
	
	if ([disclosureButton state] == NSOnState && [disclosureBox isHidden] == YES)
	{
		windowFrame.size.height += sizeChange;			// Make the window bigger.
		windowFrame.origin.y    -= sizeChange;			// Move the origin.
		[disclosureBox performSelector:@selector(setHidden:) withObject:NOasNumber afterDelay: (animate ? resizeTime : 0.0)];
		[parentWindow setFrame:windowFrame display:YES animate:animate];

	}	
	else if ([disclosureButton state] == NSOffState && [disclosureBox isHidden] == NO)
	{
		windowFrame.size.height -= sizeChange;			// Make the window smaller.
		windowFrame.origin.y    += sizeChange;			// Move the origin.
		[disclosureBox setHidden:YES];
		[parentWindow setFrame:windowFrame display:YES animate:animate];
	}

	if (animate)
		[self performSelector:@selector(restoreAutosizingMasks) withObject:nil afterDelay:resizeTime];
	else
		[self restoreAutosizingMasks];
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  SavedViewInfo
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation SavedViewInfo

@synthesize mask = mask_;
@synthesize position = position_;

+ (SavedViewInfo*)	savedViewInfoWithMask:(NSUInteger)mask position:(ViewPosition)position
{
	SavedViewInfo* info = [[SavedViewInfo alloc]init];
	[info setMask:mask];
	[info setPosition:position];
	return info;
}
@end

