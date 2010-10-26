//
//  ParentRevisionTextButtonCell.m
//  MacHg
//
//  Created by Eugene Golushkov on 26.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ParentTextButtonCell.h"
#import "MacHgDocument.h"
#import "HistoryViewController.h"

@implementation ParentTextButtonCell

@synthesize entry = entry_;


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id) init
{
	if ((self = [super init]))
	{
		entry_ = nil;
	}
	return self;
}


- (id) initWithLogEntry:(LogEntry*)entry
{
	if ((self = [super init]))
	{
		entry_ = entry;
	}
	return self;
}

+ (NSTextAttachment*) parentButtonAttachmentWithText:(NSString*)text andLogEntry:(LogEntry*)entry
{
	NSTextAttachment* attachment   = [[NSTextAttachment alloc] init];
	ParentTextButtonCell* parentCell = [[ParentTextButtonCell alloc] initWithLogEntry:entry];
	[parentCell setButtonTitle:text];
	[parentCell setBezelStyle:NSRoundRectBezelStyle];
	[parentCell setTarget:parentCell];
	[parentCell setAction:@selector(gotoParent:)];
	[attachment setAttachmentCell:parentCell];
	return attachment;
}
	
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Set members
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) setButtonTitle:(NSString*)title
{
	static NSDictionary* theDictionary = nil;
	if (theDictionary == nil)
	{
		NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		[paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		NSFont* font = [NSFont fontWithName:@"Helvetica"  size:[NSFont smallSystemFontSize]];
		theDictionary = [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
	}
	[self setAttributedTitle:[NSAttributedString string:title withAttributes:theDictionary]];
}

// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) gotoParent:(id)sender
{
	MacHgDocument* document = [[entry_ repositoryData] myDocument];
	if (![document showingASheet] && [document showingHistoryView])
	{
		NSString* title = [self title];
		NSString* revision = nil;
		if ([title getCapturesWithRegexAndComponents:@"(\\d+):[\\d\\w]+" firstComponent:&revision])
		{
			[[[document theHistoryView] logTableView] scrollToRevision:revision];
		}
	}
}

@end
