//
//  LabelData.m
//  MacHg
//
//  Created by Jason Harris on 4/10/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "LabelData.h"
#import "Common.h"

@implementation LabelData
@synthesize name	  = name_;
@synthesize revision  = revision_;
@synthesize changeset = changeset_;
@synthesize labelType = labelType_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// ------------------------------------------------------------------------------------

- (LabelData*) initWithName:(NSString*)n andType:(LabelType)t revision:(NSString*)r changeset:(NSString*)c
{
	self = [super init];
	if (self)
	{
		name_ = n;
		revision_ = stringAsNumber(r);
		changeset_ = c;
		labelType_ = t;
	}
	return self;
}

+ (LabelData*) labelWithName:(NSString*)n andType:(LabelType)t revision:(NSString*)r changeset:(NSString*)c
{
	return [[LabelData alloc] initWithName:n andType:t revision:r changeset:c];
}




// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Queries
// ------------------------------------------------------------------------------------

- (BOOL) isTag			{ return bitsInCommon(labelType_, eTagLabel); }
- (BOOL) isBookmark		{ return bitsInCommon(labelType_, eBookmarkLabel); }
- (BOOL) isBranch		{ return bitsInCommon(labelType_, eBranchLabel); }
- (BOOL) isOpenHead		{ return bitsInCommon(labelType_, eOpenHead); }
- (BOOL) isLocal		{ return bitsInCommon(labelType_, eLocalLabel); }
- (BOOL) isStationary	{ return bitsInCommon(labelType_, eStationaryLabel); }


- (BOOL) isEqualToLabel:(LabelData*)label
{
	if (![[self name] isEqualToString:[label name]])
		return NO;
	if (![[self revision] isEqualToNumber:[label revision]])
		return NO;
	if (![[self changeset] isEqualToString:[label changeset]])
		return NO;
	if ([self labelType] != [label labelType])
		return NO;
	return YES;
}


- (NSString*) revisionStr { return numberAsString(revision_); }

- (NSString*) labelTypeDescription
{
	switch ([self labelType])
	{
		case eLocalTag:			return @"Tag (Local)";
		case eGlobalTag:		return @"Tag (Global)";
		case eBookmark:			return @"Bookmark";
		case eActiveBranch:		return @"Branch (Active)";
		case eInactiveBranch:	return @"Branch (Inactive)";
		case eClosedBranch:		return @"Branch (Closed)";
		case eOpenHead:			return @"Open Head";
		default:
		case eNoLabelType:		return @"NoLabelType";
	}
}

- (NSAttributedString*) labelTypeAttributedDescription
{
	switch ([self labelType])
	{
		case eLocalTag:			return [NSAttributedString string:@"Tag"		withAttributes:smallSystemFontAttributes andString:@" (Local)"    withAttributes:smallGraySystemFontAttributes];
		case eGlobalTag:		return [NSAttributedString string:@"Tag"		withAttributes:smallSystemFontAttributes andString:@" (Global)"   withAttributes:smallGraySystemFontAttributes];
		case eBookmark:			return [NSAttributedString string:@"Bookmark"	withAttributes:smallSystemFontAttributes];
		case eActiveBranch:		return [NSAttributedString string:@"Branch"		withAttributes:smallSystemFontAttributes andString:@" (Active)"   withAttributes:smallGraySystemFontAttributes];
		case eInactiveBranch:	return [NSAttributedString string:@"Branch"		withAttributes:smallSystemFontAttributes andString:@" (Inactive)" withAttributes:smallGraySystemFontAttributes];
		case eClosedBranch:		return [NSAttributedString string:@"Branch"		withAttributes:smallSystemFontAttributes andString:@" (Closed)"	  withAttributes:smallGraySystemFontAttributes];
		case eOpenHead:			return [NSAttributedString string:@"Open Head"	withAttributes:smallSystemFontAttributes];
		default:
		case eNoLabelType:		return [NSAttributedString string:@"No Label Type" withAttributes:smallGraySystemFontAttributes];
	}
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Operations on Lists of Labels
// ------------------------------------------------------------------------------------

+ (NSArray*) filterLabels:(NSArray*)labels byType:(LabelType)type
{
	NSMutableArray* newArrayOfLabels = [[NSMutableArray alloc] init];
	for (LabelData* label in labels)
		if (bitsInCommon([label labelType], type))
			[newArrayOfLabels addObject:label];
	return newArrayOfLabels;
}

+ (NSArray*) extractNameFromLabels:(NSArray*)labels
{
	NSMutableArray* newArrayOfNames = [[NSMutableArray alloc] init];
	for (LabelData* label in labels)
		[newArrayOfNames addObject:[label name]];
	return newArrayOfNames;
}

+ (NSArray*) filterLabelsAndExtractNames:(NSArray*)labels byType:(LabelType)type
{
	NSArray* filteredLabels = [LabelData filterLabels:labels byType:type];
	NSArray* sortedLabels = [filteredLabels sortedArrayUsingDescriptors:[LabelData descriptorsForSortByNameAscending]];
	return [LabelData extractNameFromLabels:sortedLabels];
}

// This sorts the array as a side effect
+ (NSArray*) removeDuplicateLabels:(NSArray*)labels
{
	NSArray* sortedLabels = [labels sortedArrayUsingDescriptors:[self descriptorsForSortByNameAscending]];
	NSMutableArray* newLabels = [[NSMutableArray alloc] init];
	for (LabelData* label in sortedLabels)
		if (![label isEqualToLabel:[newLabels lastObject]])
			  [newLabels addObject:label];
	return newLabels;
}

+ (NSArray*) filterLabelsDictionary:(NSDictionary*)labelsDict byType:(LabelType)type
{
	NSMutableArray* newArrayOfLabels = [[NSMutableArray alloc] init];
	for (NSArray* labelArray in [labelsDict allValues])
		for (LabelData* label in labelArray)
			if (bitsInCommon([label labelType], type))
				[newArrayOfLabels addObject:label];
	return newArrayOfLabels;
}






// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Label Sorting
// ------------------------------------------------------------------------------------

// The prevalent order for sorting is by Revision, then by name, then by type. Thus if we are sorting by name we would sort by
// name then revision then by type.

+ (NSArray*) descriptorsForSortByNameAscending
{
	static NSArray* descriptors = nil;
	if (descriptors)
		return descriptors;
	NSSortDescriptor* byName = [NSSortDescriptor sortDescriptorWithKey:@"name"					ascending:YES  selector:@selector(caseInsensitiveCompare:)];
	NSSortDescriptor* byRev  = [NSSortDescriptor sortDescriptorWithKey:@"revision"				ascending:YES  selector:@selector(compare:)];
	NSSortDescriptor* byType = [NSSortDescriptor sortDescriptorWithKey:@"labelTypeDescription"	ascending:YES  selector:@selector(compare:)];
	descriptors = @[byName, byRev, byType];
	return descriptors;
}

+ (NSArray*) descriptorsForSortByRevisionAscending
{
	static NSArray* descriptors = nil;
	if (descriptors)
		return descriptors;
	NSSortDescriptor* byName = [NSSortDescriptor sortDescriptorWithKey:@"name"					ascending:YES  selector:@selector(caseInsensitiveCompare:)];
	NSSortDescriptor* byRev  = [NSSortDescriptor sortDescriptorWithKey:@"revision"				ascending:YES  selector:@selector(compare:)];
	NSSortDescriptor* byType = [NSSortDescriptor sortDescriptorWithKey:@"labelTypeDescription"	ascending:YES  selector:@selector(compare:)];
	descriptors = @[byRev, byName, byType];
	return descriptors;
}

+ (NSArray*) descriptorsForSortByTypeAscending
{
	static NSArray* descriptors = nil;
	if (descriptors)
		return descriptors;
	NSSortDescriptor* byName = [NSSortDescriptor sortDescriptorWithKey:@"name"					ascending:YES  selector:@selector(caseInsensitiveCompare:)];
	NSSortDescriptor* byRev  = [NSSortDescriptor sortDescriptorWithKey:@"revision"				ascending:YES  selector:@selector(compare:)];
	NSSortDescriptor* byType = [NSSortDescriptor sortDescriptorWithKey:@"labelTypeDescription"	ascending:YES  selector:@selector(compare:)];
	descriptors = @[byType, byRev, byName];
	return descriptors;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Utilities
// ------------------------------------------------------------------------------------

- (NSString*) description { return fstr(@"name:%@, revision:%@, type:%d",name_, revision_, labelType_); }





@end
