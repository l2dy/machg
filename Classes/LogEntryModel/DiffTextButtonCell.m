//
//  DiffTextButtonCell.m
//  MacHg
//
//  Created by Jason Harris on 5/22/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import "DiffTextButtonCell.h"
#import "MacHgDocument.h"


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
	DiffTextButtonCell* dtbc = [[DiffTextButtonCell alloc] initWithLogEntry:entry];
	[dtbc setButtonTitle:file];
	[dtbc setFileNameFromRelativeName:file];
	[dtbc setBezelStyle:NSRoundRectBezelStyle];
	[dtbc setTarget:dtbc];
	[dtbc setAction:@selector(displayDiff:)];
	[attachment setAttachmentCell:dtbc];
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
		
		NSColor* redTextColor   = [NSColor colorWithDeviceRed:(100.0/255.0) green:(  0.0/255.0) blue:(  0.0/255.0) alpha:1.0];
		NSColor* greenTextColor = [NSColor colorWithDeviceRed:(  0.0/255.0) green:(100.0/255.0) blue:(  0.0/255.0) alpha:1.0];
		NSColor* blueTextColor  = [NSColor colorWithDeviceRed:(  0.0/255.0) green:(  0.0/255.0) blue:(100.0/255.0) alpha:1.0];
		
		theDictionaryAdded    = [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, greenTextColor, NSForegroundColorAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
		theDictionaryModified = [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, blueTextColor,  NSForegroundColorAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
		theDictionaryRemoved  = [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, redTextColor,   NSForegroundColorAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
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
	NSString* rev       = [backingLogEntry_ revision];
	NSArray* parents    = [backingLogEntry_ parentsOfEntry];
	NSString* parentRev = nil;

	if (IsNotEmpty(parents))
		parentRev = [parents objectAtIndex:0];
	else
		parentRev = intAsString(MAX(0, stringAsInt(rev) - 1));

	NSString* revisionNumbers = fstr(@"%@%:%@", parentRev, rev);

	[document viewDifferencesInCurrentRevisionFor:[NSArray arrayWithObject:absoluteFileName_] toRevision:revisionNumbers];
}


@end
