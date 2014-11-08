//
//  DisclosureBoxController.m
//  MacHg
//
//  Created by Jason Harris on 22/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "DisclosureBoxController.h"

static NSInteger disclosureAnimationCount = 0;

@interface DisclosureBoxController (PrivateAPI)
- (CGFloat) sizeChange;
- (void)	saveAutosizingMasksAndRelativePositions;
- (void)	openDisclosureBoxWithAnimation:(BOOL)animate;
- (void)	closeDisclosureBoxWithAnimation:(BOOL)animate;
@end


// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  DisclosureBoxController
// ------------------------------------------------------------------------------------
// MARK: -

@implementation DisclosureBoxController

@synthesize disclosureBox;

- (void) awakeFromNib
{
	NSString* frameName  = parentWindow.frameAutosaveName;
	autoSaveName_        = IsNotEmpty(frameName) ? fstr(@"%@:disclosed", frameName) : nil;
	animationDepth_      = 0;
	disclosureIsVisible_ = YES;		// The disclosure is always open on initialization
	[self saveAutosizingMasksAndRelativePositions];
}


// If we need to optionally restore the state of the disclosure to its last saved state we can easily do so
- (void) resoreToSavedState
{
	BOOL disclosed       = autoSaveName_ ? [NSUserDefaults.standardUserDefaults boolForKey:autoSaveName_] : NO;
	[self setToOpenState:disclosed withAnimation:NO];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Styling
// ------------------------------------------------------------------------------------

- (void)	 setBackgroundToBad	 { disclosureBox.fillColor = NSColor.errorColor; }
- (void)	 setBackgroundToGood { disclosureBox.fillColor = NSColor.successColor; }
- (void)	 roundTheBoxCorners  { disclosureBox.cornerRadius = 6; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Resizing control
// ------------------------------------------------------------------------------------

- (void) saveAutosizingMasksAndRelativePositions
{
	@synchronized(self)
	{
		if (!savedViewsInfo)
			savedViewsInfo = NSMapTable.mapTableWithWeakToStrongObjects;
	}

	NSRect discloseRect = disclosureBox.frame;
	NSArray* viewsInWindow = [parentWindow.contentView subviews];
	for (NSView* view in viewsInWindow)
		if (![savedViewsInfo objectForKey:view])
		{
			ViewPosition position = (NSMaxY(view.frame) > NSMaxY(discloseRect)) ? eViewAboveDisclosure : eViewBelowDisclosure;
			SavedViewInfo* info = [SavedViewInfo savedViewInfoWithMask:view.autoresizingMask position:position];
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

		disclosureAnimationCount++;	// Up the overall animation count

		// If we are already animating then we are already in the correct state
		if (animationDepth_ > 1)
			return;


		savedShowsResizeIndicator_ = parentWindow.showsResizeIndicator;
		parentWindow.showsResizeIndicator = NO;
		
		for (NSView* view in savedViewsInfo)
		{
			SavedViewInfo* info = DynamicCast(SavedViewInfo,[savedViewsInfo objectForKey:view]);
			if (!info)
				continue;	// Should we raise an assert here?
			if (info.position == eViewAboveDisclosure)
				view.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
			else
				view.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
		}
	}
}


- (void) restoreStateAfterDisclosure
{
	@synchronized(self)
	{
		animationDepth_--;
	
		// If we are still animating then don't restore the state yet
		if (animationDepth_ == 0)
		{
			for (NSView* view in savedViewsInfo)
			{
				SavedViewInfo* info = DynamicCast(SavedViewInfo,[savedViewsInfo objectForKey:view]);
				if (info)
					view.autoresizingMask = info.mask;
			}
			
			if (savedShowsResizeIndicator_)
				parentWindow.showsResizeIndicator = YES;
		}
		
		disclosureAnimationCount--;
	}
}


- (CGFloat) sizeChange	{ return disclosureBox.frame.size.height + 5; } 		// The extra +5 accounts for the space between the box and its neighboring views

- (BOOL)	disclosureIsVisible { return disclosureIsVisible_; }




// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// ------------------------------------------------------------------------------------

- (IBAction) disclosureTrianglePressed:(id)sender
{
	@synchronized(self)
	{
		[self setToOpenState:(disclosureButton.state == NSOnState) withAnimation:YES];
	}
}

- (void) ensureDisclosureBoxIsOpen:(BOOL)animate
{
	@synchronized(self)
	{
		disclosureButton.state = NSOnState;
		if (disclosureIsVisible_)
			return;
		[self openDisclosureBoxWithAnimation:animate];
	}
}


- (void) ensureDisclosureBoxIsClosed:(BOOL)animate
{
	@synchronized(self)
	{
		disclosureButton.state = NSOffState;
		if (!disclosureIsVisible_)
			return;
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
		[NSUserDefaults.standardUserDefaults setBool:disclosureIsVisible_ forKey:autoSaveName_];
	
	NSRect windowFrame = parentWindow.frame;
	CGFloat sizeChange = self.sizeChange;
	
	NSTimeInterval resizeTime = [parentWindow animationResizeTime:windowFrame];
	animate = (disclosureAnimationCount > 0) ? NO : animate;
	[self setStateForDisclose];
	
	windowFrame.size.height += sizeChange;			// Make the window bigger.
	windowFrame.origin.y    -= sizeChange;			// Move the origin.
	
	// Adjust the min and max window sizes to account for showing the disclosure box. This content sizing doesn't affect the
	// resizing via parentWindow.frame = ... below
	NSSize contentMinSize = parentWindow.contentMinSize;
	NSSize contentMaxSize = parentWindow.contentMaxSize;
	if (isfinite(contentMinSize.height) && contentMinSize.height > 0)
	{
		contentMinSize.height += sizeChange;
		parentWindow.contentMinSize = contentMinSize;
	}
	if (isfinite(contentMaxSize.height) && contentMaxSize.height > 0)
	{
		contentMaxSize.height += sizeChange;
		parentWindow.contentMaxSize = contentMaxSize;
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
		[NSUserDefaults.standardUserDefaults setBool:disclosureIsVisible_ forKey:autoSaveName_];
	
	NSRect windowFrame = parentWindow.frame;
	CGFloat sizeChange = self.sizeChange;

	NSTimeInterval resizeTime = [parentWindow animationResizeTime:windowFrame];
	animate = (disclosureAnimationCount > 0) ? NO : animate;
	[self setStateForDisclose];
	
	windowFrame.size.height -= sizeChange;			// Make the window smaller.
	windowFrame.origin.y    += sizeChange;			// Move the origin.

	// Adjust the min and max window sizes to account for hiding the disclosure box. This content sizing doesn't affect the
	// resizing via parentWindow.frame = ... below
	NSSize contentMinSize = parentWindow.contentMinSize;
	NSSize contentMaxSize = parentWindow.contentMaxSize;
	if (isfinite(contentMinSize.height) && contentMinSize.height > sizeChange)
	{
		contentMinSize.height -= sizeChange;
		parentWindow.contentMinSize = contentMinSize;
	}
	if (isfinite(contentMaxSize.height) && contentMaxSize.height > sizeChange)
	{
		contentMaxSize.height -= sizeChange;
		parentWindow.contentMaxSize = contentMaxSize;
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:disclosureBox selector:@selector(setHidden:) object:NOasNumber];	// Cancel any other requests to show the object
	disclosureBox.hidden = YES;
	[parentWindow setFrame:windowFrame display:YES animate:animate];

	if (animate)
		[self performSelector:@selector(restoreStateAfterDisclosure) withObject:nil afterDelay:resizeTime];
	else
		[self restoreStateAfterDisclosure];
}

@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  SavedViewInfo
// ------------------------------------------------------------------------------------
// MARK: -

@implementation SavedViewInfo

@synthesize mask = mask_;
@synthesize position = position_;

+ (SavedViewInfo*)	savedViewInfoWithMask:(NSUInteger)mask position:(ViewPosition)position
{
	SavedViewInfo* info = [[SavedViewInfo alloc]init];
	info.mask = mask;
	info.position = position;
	return info;
}
@end

