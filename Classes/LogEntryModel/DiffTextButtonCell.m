//
//  DiffTextButtonCell.m
//  MacHg
//
//  Created by Jason Harris on 5/22/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import "DiffTextButtonCell.h"


@implementation DiffTextButtonCell

@synthesize absoluteFileName = absoluteFileName_;
@synthesize backingLogEntry = backingLogEntry_;

- (void) setFileNameFromRelativeName:(NSString*)relativeName
{
	MacHgDocument* document = [[backingLogEntry_ repositoryData] myDocument];
	absoluteFileName_ = [[document absolutePathOfRepositoryRoot] stringByAppendingPathComponent:relativeName];
}

- (IBAction) displayDiff:(id)sender
{
	MacHgDocument* document = [[backingLogEntry_ repositoryData] myDocument];
	NSString* rev       = [backingLogEntry_ revision];
	NSArray* parents    = [backingLogEntry_ parents];
	NSString* parentRev = nil;

	if (IsNotEmpty(parents))
		parentRev = [parents objectAtIndex:0];
	else
		parentRev = intAsString(MAX(0, stringAsInt(rev) - 1));

	NSString* revisionNumbers = fstr(@"%@%:%@", parentRev, rev);

	[document viewDifferencesInCurrentRevisionFor:absoluteFileName_ toRevision:revisionNumbers];
}


@end
