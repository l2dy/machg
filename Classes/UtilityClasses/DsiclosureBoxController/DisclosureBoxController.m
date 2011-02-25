//
//  DisclosureBoxController.m
//  MacHg
//
//  Created by Jason Harris on 22/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "DisclosureBoxController.h"


@interface DisclosureBoxController (PrivateAPI)
- (CGFloat) sizeChange;
- (void)	openDisclosureBoxWithAnimation:(BOOL)animate;
- (void)	closeDisclosureBoxWithAnimation:(BOOL)animate;
@end


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  DisclosureBoxController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation DisclosureBoxController

@synthesize disclosureBox;

- (void) awakeFromNib
{
	NSString* frameName  = [parentWindow frameAutosaveName];
	NSRect frameRect     = [parentWindow frame];
	autoSaveName_        = IsNotEmpty(frameName) ? fstr(@"%@:disclosed", frameName) : nil;
	BOOL disclosed       = autoSaveName_ ? [[NSUserDefaults standardUserDefaults] boolForKey:autoSaveName_] : NO;
	animationDepth_      = 0;
	disclosureIsVisible_ = YES;		// The disclosure is always open on initialization

	[self setToOpenState:disclosed withAnimation:NO];
	if (!disclosed && autoSaveName_)
		[parentWindow setFrame:frameRect display:NO animate:NO];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Styling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void)	 setBackgroundToBad	 { [disclosureBox setFillColor:[NSColor errorColor]]; }
- (void)	 setBackgroundToGood { [disclosureBox setFillColor:[NSColor successColor]]; }
- (void)	 roundTheBoxCorners  { [disclosureBox setCornerRadius:6]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Resizing control
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) saveAutosizingMasksAndRelativePositions
{
	@synchronized(self)
	{
		if (!savedViewsInfo)
			savedViewsInfo = [NSMapTable mapTableWithWeakToStrongObjects];
	}

	NSRect discloseRect = [disclosureBox frame];
	NSArray* viewsInWindow = [[parentWindow contentView] subviews];
	for (NSView* view in viewsInWindow)
		if (![savedViewsInfo objectForKey:view])
		{
			ViewPosition position = (NSMaxY([view frame]) > NSMaxY(discloseRect)) ? eViewAboveDisclosure : eViewBelowDisclosure;
			SavedViewInfo* info = [SavedViewInfo savedViewInfoWithMask:[view autoresizingMask] position:position];
			[savedViewsInfo setObject:info forKey:view];
		}
}


- (void) setStateForDisclose
{
	@synchronized(self)
	{
		if (animationDepth_ < 0)
			animationDepth_ = 0;
		animationDepth_++;

		// If we are already animating then we are already in the correct state
		if (animationDepth_ > 1)
			return;
			
		savedShowsResizeIndicator_ = [parentWindow showsResizeIndicator];
		[parentWindow setShowsResizeIndicator:NO];
		
		for (NSView* view in savedViewsInfo)
		{
			SavedViewInfo* info = DynamicCast(SavedViewInfo,[savedViewsInfo objectForKey:view]);
			if (!info)
				continue;	// Should we raise an assert here?
			if ([info position] == eViewAboveDisclosure)
				[view setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
			else
				[view setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
		}
	}
}


- (void) restoreStateAfterDisclosure
{
	@synchronized(self)
	{
		animationDepth_--;
	
		// If we are still animating then don't restore the state yet
		if (animationDepth_ > 0)
			return;
	
		for (NSView* view in savedViewsInfo)
		{
			SavedViewInfo* info = DynamicCast(SavedViewInfo,[savedViewsInfo objectForKey:view]);
			if (info)
				[view setAutoresizingMask:[info mask]];
		}
		
		if (savedShowsResizeIndicator_)
			[parentWindow setShowsResizeIndicator:YES];
	}
}


- (CGFloat) sizeChange	{ return [disclosureBox frame].size.height + 5; } 		// The extra +5 accounts for the space between the box and its neighboring views

- (BOOL)	disclosureIsVisible { return disclosureIsVisible_; }




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) disclosureTrianglePressed:(id)sender
{
	@synchronized(self)
	{
		[self setToOpenState:([disclosureButton state] == NSOnState) withAnimation:YES];
	}
}

- (void) ensureDisclosureBoxIsOpen:(BOOL)animate
{
	@synchronized(self)
	{
		if (disclosureIsVisible_)
			return;
		[disclosureButton setState:NSOnState];
		[self openDisclosureBoxWithAnimation:animate];
	}
}


- (void) ensureDisclosureBoxIsClosed:(BOOL)animate
{
	@synchronized(self)
	{
		if (!disclosureIsVisible_)
			return;
		[disclosureButton setState:NSOffState];
		[self closeDisclosureBoxWithAnimation:animate];
	}
}


- (void) setToOpenState:(BOOL)state withAnimation:(BOOL)animate
{
	if (state == YES)
		[self ensureDisclosureBoxIsOpen:animate];
	else if (state == NO)
		[self ensureDisclosureBoxIsClosed:animate];
}


- (void) openDisclosureBoxWithAnimation:(BOOL)animate
{
	disclosureIsVisible_ = YES;
	[self saveAutosizingMasksAndRelativePositions];
	if (autoSaveName_)
		[[NSUserDefaults standardUserDefaults] setBool:disclosureIsVisible_ forKey:autoSaveName_];
	
	NSRect windowFrame = [parentWindow frame];
	CGFloat sizeChange = [self sizeChange];
	
	NSTimeInterval resizeTime = [parentWindow animationResizeTime:windowFrame];
	[self setStateForDisclose];
	
	windowFrame.size.height += sizeChange;			// Make the window bigger.
	windowFrame.origin.y    -= sizeChange;			// Move the origin.
	
	// Adjust the min and max window sizes to account for showing the disclosure box. This content sizing doesn't affect the
	// resizing via [parentWindow setFrame:...] below
	NSSize contentMinSize = [parentWindow contentMinSize];
	NSSize contentMaxSize = [parentWindow contentMaxSize];
	if (isfinite(contentMinSize.height) && contentMinSize.height > 0)
	{
		contentMinSize.height += sizeChange;
		[parentWindow setContentMinSize:contentMinSize];
	}
	if (isfinite(contentMaxSize.height) && contentMaxSize.height > 0)
	{
		contentMaxSize.height += sizeChange;
		[parentWindow setContentMaxSize:contentMaxSize];
	}
	
	[disclosureBox performSelector:@selector(setHidden:) withObject:NOasNumber afterDelay: (animate ? resizeTime : 0.0)];
	[parentWindow setFrame:windowFrame display:YES animate:animate];

	if (animate)
		[self performSelector:@selector(restoreStateAfterDisclosure) withObject:nil afterDelay:resizeTime];
	else
		[self restoreStateAfterDisclosure];
}


- (void) closeDisclosureBoxWithAnimation:(BOOL)animate
{
	disclosureIsVisible_ = NO;
	[self saveAutosizingMasksAndRelativePositions];
	if (autoSaveName_)
		[[NSUserDefaults standardUserDefaults] setBool:disclosureIsVisible_ forKey:autoSaveName_];
	
	NSRect windowFrame = [parentWindow frame];
	CGFloat sizeChange = [self sizeChange];

	NSTimeInterval resizeTime = [parentWindow animationResizeTime:windowFrame];
	[self setStateForDisclose];
	
	windowFrame.size.height -= sizeChange;			// Make the window smaller.
	windowFrame.origin.y    += sizeChange;			// Move the origin.

	// Adjust the min and max window sizes to account for hiding the disclosure box. This content sizing doesn't affect the
	// resizing via [parentWindow setFrame:...] below
	NSSize contentMinSize = [parentWindow contentMinSize];
	NSSize contentMaxSize = [parentWindow contentMaxSize];
	if (isfinite(contentMinSize.height) && contentMinSize.height > sizeChange)
	{
		contentMinSize.height -= sizeChange;
		[parentWindow setContentMinSize:contentMinSize];
	}
	if (isfinite(contentMaxSize.height) && contentMaxSize.height > sizeChange)
	{
		contentMaxSize.height -= sizeChange;
		[parentWindow setContentMaxSize:contentMaxSize];
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:disclosureBox selector:@selector(setHidden:) object:NOasNumber];	// Cancel any other requests to show the object
	[disclosureBox setHidden:YES];
	[parentWindow setFrame:windowFrame display:YES animate:animate];

	if (animate)
		[self performSelector:@selector(restoreStateAfterDisclosure) withObject:nil afterDelay:resizeTime];
	else
		[self restoreStateAfterDisclosure];
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

