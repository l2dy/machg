//
//  StatusButton.m
//  MacHg
//
//  Created by Jason Harris on 2/27/12.
//  Copyright 2012 Jason F Harris. All rights reserved.
//

#import "StatusButton.h"
#import "Common.h"
#import "FSNodeInfo.h"

NSString* kKeyPathShowAdded		 = @"values.ShowAddedFilesInBrowser";
NSString* kKeyPathShowModified	 = @"values.ShowModifiedFilesInBrowser";
NSString* kKeyPathShowClean		 = @"values.ShowCleanFilesInBrowser";
NSString* kKeyPathShowRemoved	 = @"values.ShowRemovedFilesInBrowser";
NSString* kKeyPathShowMissing	 = @"values.ShowMissingFilesInBrowser";
NSString* kKeyPathShowUntracked	 = @"values.ShowUntrackedFilesInBrowser";
NSString* kKeyPathShowIgnored	 = @"values.ShowIgnoredFilesInBrowser";
NSString* kKeyPathShowUnResolved = @"values.ShowUnResolvedFilesInBrowser";
NSString* kKeyPathShowResolved	 = @"values.ShowResolvedFilesInBrowser";
NSString* kKeyPathShowFileIcons	 = @"values.DisplayFileIconsInBrowser";


@implementation StatusButton

- (void) awakeFromNib
{
	// Bind the show / hide of the column to the preferences LogEntryTableDisplayChangesetColumn which is bound to a checkbox in the prefs.
	id defaults = [NSUserDefaultsController sharedUserDefaultsController];
	
	// Receive a notification when the tag highlight color changes.
	[defaults  addObserver:self  forKeyPath:kKeyPathShowAdded		options:NSKeyValueObservingOptionNew  context:NULL];
	[defaults  addObserver:self  forKeyPath:kKeyPathShowModified	options:NSKeyValueObservingOptionNew  context:NULL];
	[defaults  addObserver:self  forKeyPath:kKeyPathShowClean		options:NSKeyValueObservingOptionNew  context:NULL];
	[defaults  addObserver:self  forKeyPath:kKeyPathShowRemoved		options:NSKeyValueObservingOptionNew  context:NULL];
	[defaults  addObserver:self  forKeyPath:kKeyPathShowMissing		options:NSKeyValueObservingOptionNew  context:NULL];
	[defaults  addObserver:self  forKeyPath:kKeyPathShowUntracked	options:NSKeyValueObservingOptionNew  context:NULL];
	[defaults  addObserver:self  forKeyPath:kKeyPathShowIgnored		options:NSKeyValueObservingOptionNew  context:NULL];
	[defaults  addObserver:self  forKeyPath:kKeyPathShowUnResolved	options:NSKeyValueObservingOptionNew  context:NULL];
	[defaults  addObserver:self  forKeyPath:kKeyPathShowResolved	options:NSKeyValueObservingOptionNew  context:NULL];
	[defaults  addObserver:self  forKeyPath:kKeyPathShowFileIcons	options:NSKeyValueObservingOptionNew  context:NULL];
	[self refreshButtonImage:self];
}

- (void) dealloc
{
	id defaults = [NSUserDefaultsController sharedUserDefaultsController];	
	[defaults  removeObserver:self forKeyPath:kKeyPathShowAdded];
	[defaults  removeObserver:self forKeyPath:kKeyPathShowModified];
	[defaults  removeObserver:self forKeyPath:kKeyPathShowClean];
	[defaults  removeObserver:self forKeyPath:kKeyPathShowRemoved];
	[defaults  removeObserver:self forKeyPath:kKeyPathShowMissing];
	[defaults  removeObserver:self forKeyPath:kKeyPathShowUntracked];
	[defaults  removeObserver:self forKeyPath:kKeyPathShowIgnored];
	[defaults  removeObserver:self forKeyPath:kKeyPathShowUnResolved];
	[defaults  removeObserver:self forKeyPath:kKeyPathShowResolved];
	[defaults  removeObserver:self forKeyPath:kKeyPathShowFileIcons];
}

- (void) observeValueForKeyPath:(NSString*)keyPath  ofObject:(id)object  change:(NSDictionary*)change  context:(void*)context
{
    if ([keyPath isEqualToString:kKeyPathShowAdded] ||
		[keyPath isEqualToString:kKeyPathShowModified] ||
		[keyPath isEqualToString:kKeyPathShowClean] ||
		[keyPath isEqualToString:kKeyPathShowRemoved] ||
		[keyPath isEqualToString:kKeyPathShowMissing] ||
		[keyPath isEqualToString:kKeyPathShowUntracked] ||
		[keyPath isEqualToString:kKeyPathShowIgnored] ||
		[keyPath isEqualToString:kKeyPathShowUnResolved] ||
		[keyPath isEqualToString:kKeyPathShowResolved] ||
		[keyPath isEqualToString:kKeyPathShowFileIcons])
		[self refreshButtonImage:self];
}


- (IBAction) refreshButtonImage:(id)sender
{
	static BOOL initalizedCaches    = NO;
	static NSImage* finderIconImage = nil;	
	static NSImage* additionImage   = nil;
	static NSImage* cleanImage      = nil;
	static NSImage* blankImage      = nil;
	static NSImage* missingImage    = nil;
	static NSImage* ignoredImage    = nil;
	static NSImage* modifiedImage   = nil;
	static NSImage* removedImage    = nil;
	static NSImage* unknownImage    = nil;
	static NSImage* unresolvedImage = nil;
	static NSImage* resolvedImage   = nil;
	static NSImage* downArrowImage  = nil;

	if (!initalizedCaches)
	{
		NSSize theIconSize = NSMakeSize(ICON_SIZE, ICON_SIZE);
		initalizedCaches = YES;
		additionImage    = [NSImage imageNamed:@"StatusAdded.png"];
		cleanImage       = [NSImage imageNamed:@"GrayBall.png"];
		blankImage       = [NSImage imageNamed:@"Blank.png"];
		missingImage     = [NSImage imageNamed:@"StatusMissing.png"];
		ignoredImage     = [NSImage imageNamed:@"StatusIgnored.png"];
		modifiedImage    = [NSImage imageNamed:@"StatusModified.png"];
		removedImage     = [NSImage imageNamed:@"StatusRemoved.png"];
		unknownImage     = [NSImage imageNamed:@"StatusUnversioned.png"];
		unresolvedImage  = [NSImage imageNamed:@"StatusUnresolved.png"];
		resolvedImage    = [NSImage imageNamed:@"StatusResolved.png"];
		finderIconImage  = [NSImage imageNamed:@"FinderIcon.png"];
		downArrowImage   = [NSImage imageNamed:@"ButtonDownArrow.png"];

		[additionImage		setSize:theIconSize];
		[cleanImage			setSize:theIconSize];
		[missingImage		setSize:theIconSize];
		[ignoredImage		setSize:theIconSize];
		[modifiedImage		setSize:theIconSize];
		[removedImage		setSize:theIconSize];
		[unknownImage		setSize:theIconSize];
		[unresolvedImage	setSize:theIconSize];
		[blankImage			setSize:theIconSize];		
		[finderIconImage	setSize:theIconSize];
		[downArrowImage     setSize:theIconSize];
	}
	
	NSMutableArray* icons = [[NSMutableArray alloc] init];

	if (DisplayFileIconsInBrowserFromDefaults())    [icons addObject:finderIconImage];
	if (ShowCleanFilesInBrowserFromDefaults())      [icons addObject:cleanImage];
	if (ShowAddedFilesInBrowserFromDefaults())      [icons addObject:additionImage];
	if (ShowMissingFilesInBrowserFromDefaults())    [icons addObject:missingImage];
	if (ShowIgnoredFilesInBrowserFromDefaults())    [icons addObject:ignoredImage];
	if (ShowRemovedFilesInBrowserFromDefaults())    [icons addObject:removedImage];
	if (ShowResolvedFilesInBrowserFromDefaults())   [icons addObject:resolvedImage];
	if (ShowUnresolvedFilesInBrowserFromDefaults()) [icons addObject:unresolvedImage];
	if (ShowUntrackedFilesInBrowserFromDefaults())  [icons addObject:unknownImage];
	if (ShowModifiedFilesInBrowserFromDefaults())   [icons addObject:modifiedImage];

	[icons addObject:blankImage];
	[icons addObject:downArrowImage];
	
	NSImage* combinedImage = [FSNodeInfo compositeRowOfIcons:icons withOverlap:1.5];
	[self setImage:combinedImage];
	NSRect newFrame = [self frame];
	newFrame.size.width = combinedImage.size.width + 8;
	[self setFrame:newFrame];
}

@end
