//
//  DiffTextButtonCell.m
//  MacHg
//
//  Created by Jason Harris on 5/22/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import "DiffTextButtonCell.h"
#import "MacHgDocument.h"
#import "RepositoryData.h"

@implementation DiffTextButtonCell

@synthesize type = type_;
@synthesize absoluteFileName = absoluteFileName_;
@synthesize backingLogEntry = backingLogEntry_;


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id) init
{
	if ((self = [super init]))
	{
		type_ = eDiffFileChanged;
	}
	return self;
}


- (id) initWithLogEntry:(LogEntry*)entry
{
	if ((self = [super init]))
	{
		type_ = eDiffFileChanged;
		backingLogEntry_ = entry;
	}
	return self;
}


+ (NSTextAttachment*) diffButtonAttachmentWithLogEntry:(LogEntry*)entry andFile:(NSString*)file andType:(DiffButtonType)t
{
	NSTextAttachment* attachment     = [[NSTextAttachment alloc] init];
	DiffTextButtonCell* diffCell = [[DiffTextButtonCell alloc] initWithLogEntry:entry];
	[diffCell setType:t];
	[diffCell setButtonTitle:file];
	[diffCell setFileNameFromRelativeName:file];
	[diffCell setBezelStyle:NSRoundRectBezelStyle];
	[diffCell setTarget:diffCell];
	[diffCell setAction:@selector(displayDiff:)];
	[attachment setAttachmentCell:diffCell];
	return attachment;
}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Set members
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) setButtonTitle:(NSString*)title
{
	static NSDictionary* theDictionaryAdded = nil;
	static NSDictionary* theDictionaryModified = nil;
	static NSDictionary* theDictionaryRemoved = nil;
	if (theDictionaryAdded == nil)
	{
		NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		[paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		NSFont* font = [NSFont controlContentFontOfSize:[NSFont systemFontSize]];
		
		NSColor* redTextColor   = rgbColor255(100.0,   0.0,   0.0);
		NSColor* greenTextColor = rgbColor255(  0.0, 100.0,   0.0);
		NSColor* blueTextColor  = rgbColor255(  0.0,   0.0, 100.0);
		
		theDictionaryAdded    = @{NSFontAttributeName: font, NSForegroundColorAttributeName: greenTextColor, NSParagraphStyleAttributeName: paragraphStyle};
		theDictionaryModified = @{NSFontAttributeName: font, NSForegroundColorAttributeName: blueTextColor, NSParagraphStyleAttributeName: paragraphStyle};
		theDictionaryRemoved  = @{NSFontAttributeName: font, NSForegroundColorAttributeName: redTextColor, NSParagraphStyleAttributeName: paragraphStyle};
	}

	NSDictionary* attributes = nil;
	switch (type_)
	{
		case eDiffFileAdded:   attributes = theDictionaryAdded;    break;
		case eDiffFileChanged: attributes = theDictionaryModified; break;
		case eDiffFileRemoved: attributes = theDictionaryRemoved;  break;
	}
	[self setAttributedTitle:[NSAttributedString string:title withAttributes:attributes]];
}

- (void) setFileNameFromRelativeName:(NSString*)relativeName
{
	MacHgDocument* document = [[backingLogEntry_ repositoryData] myDocument];
	absoluteFileName_ = [[document absolutePathOfRepositoryRoot] stringByAppendingPathComponent:relativeName];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) displayDiff:(id)sender
{
	MacHgDocument* document = [[backingLogEntry_ repositoryData] myDocument];
	NSNumber* rev       = [backingLogEntry_ revision];
	NSNumber* parentRev = [backingLogEntry_ firstParent];
	NSString* revisionNumbers = fstr(@"%@%:%@", parentRev, rev);

	[document viewDifferencesInCurrentRevisionFor:@[absoluteFileName_] toRevision:revisionNumbers];
}


@end
