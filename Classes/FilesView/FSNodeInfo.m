//
//  FSNodeInfo.m
//  Author: Jason F Harris
//  Some aspects copied from Apple's example code by Chuck Pisula and Corbin Dunn
//
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//



#import "FSNodeInfo.h"
#import "AppController.h"
#import "FSViewerPaneCell.h"

@implementation FSNodeInfo

@synthesize parentFSViewer;
@synthesize relativePathComponent;
@synthesize absolutePath;
@synthesize childNodes;
@synthesize sortedChildNodeKeys;
@synthesize haveComputedTheProperties;
@synthesize hgStatus;


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Queries
// -----------------------------------------------------------------------------------------------------------------------------------------

// Given a node we have its absolute path and we can query if it is a link, readable, a directory, etc....
- (BOOL) isLink
{
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSDictionary* fileAttributes = [fileManager attributesOfItemAtPath:absolutePath error:nil];
	return [[fileAttributes fileType] isEqualToString:NSFileTypeSymbolicLink];
}

- (BOOL) isDirectory
{
	if ([childNodes count]	> 0)
		return YES;
	BOOL isDir = NO;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:absolutePath isDirectory:&isDir];
	return exists && isDir;
}

- (BOOL) isFile
{
	if ([childNodes count]	> 0)
		return NO;
	BOOL isDir = NO;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:absolutePath isDirectory:&isDir];
	return exists && !isDir;
}


- (BOOL) isVisible
{
	// Make this as sophisticated for example to hide more files you don't think the user should see!
	NSString* lastPathComponent = [self lastPathComponent];
	return ([lastPathComponent length] ? ([lastPathComponent characterAtIndex:0]!='.') : NO);
}

- (BOOL)		isDirty				{ return bitsInCommon(hgStatus, eHGStatusDirty); }
- (BOOL)		isReadable			{ return [[NSFileManager defaultManager] isReadableFileAtPath:absolutePath]; }
- (NSString*)	fsType				{ return [self isDirectory] ? @"Directory" : @"Non-Directory"; }
- (NSString*)	lastPathComponent	{ return [relativePathComponent lastPathComponent]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Accessors
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSInteger)   childNodeCount						{ return [[self sortedChildNodeKeys] count]; }
- (FSNodeInfo*) childNodeAtIndex:(NSInteger)index	{ return [[self childNodes] objectForKey:[[self sortedChildNodeKeys] objectAtIndex:index]]; }

// This method must be called on theRoot node.
- (FSNodeInfo*) nodeForPathFromRoot:(NSString*)thePath
{
	NSString* theRelativePath = pathDifference([self absolutePath], thePath);
	if (IsEmpty(theRelativePath))
		return [[self absolutePath] isEqualToString:thePath] ? self : nil;
	NSArray* thePathComponents = [theRelativePath pathComponents];
	FSNodeInfo* node = self;
	for (NSString* pathPath in thePathComponents)
		node = [[node childNodes] objectForKey:pathPath];
	return node;
}

// This method must be called on theRoot node.
- (BOOL) getRow:(NSInteger*)row andColumn:(NSInteger*)column forNode:(FSNodeInfo*)goalNode
{
	if (row == nil || column == nil || goalNode == nil)
		return NO;

	*column = -1;
	*row = 0;
	NSString* thePath = [goalNode absolutePath];
	NSString* theRelativePath = pathDifference([self absolutePath], thePath);
	if (IsEmpty(theRelativePath))
		return NO;
	
	NSArray* thePathComponents = [theRelativePath pathComponents];
	FSNodeInfo* node = self;
	FSNodeInfo* childNode = self;
	for (NSString* pathPath in thePathComponents)
	{
		node = childNode;
		childNode = [[node childNodes] objectForKey:pathPath];
		(*column)++;
	}
	if (!childNode)
		return NO;
	*row = [[node sortedChildNodeKeys] indexOfObject:[thePathComponents lastObject]];
	return (*row != NSNotFound);
}




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Tree Construction Nodes
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) setHgStatus:(HGStatus) newStatus { hgStatus = newStatus; }
- (void) setHgStatusAdditively:(HGStatus) newStatus
{
	if (bitsInCommon(newStatus, eHGStatusPrimary))
	{
		hgStatus = newStatus;
		return;
	}
	if (bitsInCommon(newStatus, eHGStatusSecondary))
	{
		if (hgStatus == eHGStatusNoStatus)
		{
			hgStatus = unionBits(eHGStatusClean, newStatus);
			return;
		}
		hgStatus = unionBits(hgStatus, newStatus);
		return;
	}

	NSAssert(NO, @"should set either a primary or secondary status");
	hgStatus = eHGStatusNoStatus;
}

- (FSNodeInfo*) initRootNodeAtAbsolutePath: (NSString*)theAbsolutePath
{
	relativePathComponent = theAbsolutePath;
	absolutePath = theAbsolutePath;
	childNodes = nil;
	sortedChildNodeKeys = nil;
	hgStatus = eHGStatusNoStatus;
	return self;
}

- (FSNodeInfo*) initNewWithParent:(FSNodeInfo*)parent atRelativePath:(NSString*)path withParentViewer:(FSViewer*)viewer
{
	parentFSViewer = viewer;
	relativePathComponent = path;
	absolutePath = [[parent absolutePath] stringByAppendingPathComponent:relativePathComponent];
	childNodes = nil;
	sortedChildNodeKeys = nil;
	haveComputedTheProperties = NO;
	hgStatus = eHGStatusNoStatus;
	maxIconCountOfSubitems_ = notYetComputedIconCount;
	return self;
}


- (FSNodeInfo*) initWithNode:(FSNodeInfo*)node
{
	parentFSViewer = [node parentFSViewer];
	relativePathComponent = [node relativePathComponent];
	absolutePath = [node absolutePath];
	childNodes = [[node childNodes] mutableCopy];
	sortedChildNodeKeys = nil;
	haveComputedTheProperties = NO;
	hgStatus = eHGStatusNoStatus;
	maxIconCountOfSubitems_ = notYetComputedIconCount;
	return self;
}


+ (HGStatus) statusEnumFromLetter:(NSString*)statusLetter
{
	const char* theLetterStr = [statusLetter cStringUsingEncoding:NSUTF8StringEncoding];
	if (!theLetterStr) return eHGStatusUntracked;
	const char theLetter = theLetterStr[0];
	switch ( theLetter )
	{
		case 'M':	return eHGStatusModified;
		case 'A':	return eHGStatusAdded;
		case 'R':	return eHGStatusRemoved;
		case '!':	return eHGStatusMissing;
		case 'C':	return eHGStatusClean;
		case '?':	return eHGStatusUntracked;
		case 'I':	return eHGStatusIgnored;
		case 'U':	return eHGStatusUnresolved;
		case 'V':	return eHGStatusResolved;
		default :	return eHGStatusUntracked;
	}
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Icons for Nodes
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSImage*) iconImageOfSize:(NSSize)size
{    
	NSString* path = [self absolutePath];
	NSString* defaultImageName = [self isDirectory] ? NSImageNameFolder : @"FSIconImage-Default";
	return [NSWorkspace iconImageOfSize:size forPath:path withDefault:defaultImageName];
}

+ (NSArray*) notableIconImagesForStatus:(HGStatus)status isDirectory:(BOOL)isDirectory
{
	static BOOL initalizedCaches    = NO;
	static NSImage* additionImage   = nil;
	static NSImage* cleanImage      = nil;
	static NSImage* missingImage    = nil;
	static NSImage* ignoredImage    = nil;
	static NSImage* modifiedImage   = nil;
	static NSImage* removedImage    = nil;
	static NSImage* unknownImage    = nil;
	static NSImage* blankImage      = nil;
	static NSImage* unresolvedImage = nil;
	static NSImage* resolvedImage   = nil;
	
	if (!initalizedCaches)
	{
		NSSize theIconSize = NSMakeSize(ICON_SIZE, ICON_SIZE);
		initalizedCaches = YES;
		additionImage    = [NSImage imageNamed:@"StatusAdded.png"];
		cleanImage       = [NSImage imageNamed:@"Blank.png"];
		missingImage     = [NSImage imageNamed:@"StatusMissing.png"];
		ignoredImage     = [NSImage imageNamed:@"StatusIgnored.png"];
		modifiedImage    = [NSImage imageNamed:@"StatusModified.png"];
		removedImage     = [NSImage imageNamed:@"StatusRemoved.png"];
		unknownImage     = [NSImage imageNamed:@"StatusUnversioned.png"];
		unresolvedImage  = [NSImage imageNamed:@"StatusUnresolved.png"];
		resolvedImage    = [NSImage imageNamed:@"StatusResolved.png"];
		blankImage       = [NSImage imageNamed:@"Blank.png"];
		
		[additionImage		setSize:theIconSize];
		[cleanImage			setSize:theIconSize];
		[missingImage		setSize:theIconSize];
		[ignoredImage		setSize:theIconSize];
		[modifiedImage		setSize:theIconSize];
		[removedImage		setSize:theIconSize];
		[unknownImage		setSize:theIconSize];
		[unresolvedImage	setSize:theIconSize];
		[blankImage			setSize:theIconSize];
	}

	NSMutableArray* icons = [[NSMutableArray alloc] init];

	if (bitsInCommon(status, eHGStatusMissing))		[icons addObject:missingImage];
	if (bitsInCommon(status, eHGStatusUntracked))	[icons addObject:unknownImage];
	if (bitsInCommon(status, eHGStatusAdded))		[icons addObject:additionImage];
	if (bitsInCommon(status, eHGStatusRemoved))		[icons addObject:removedImage];
	if (bitsInCommon(status, eHGStatusModified))	[icons addObject:modifiedImage];
	if (bitsInCommon(status, eHGStatusUnresolved))	[icons addObject:unresolvedImage];
	if (bitsInCommon(status, eHGStatusResolved))	[icons addObject:resolvedImage];

	// For directories we only consider the icons above
	if (isDirectory)
		return icons;
	
	// For files we need to get the other images as well
	if (bitsInCommon(status, eHGStatusClean))		[icons addObject:cleanImage];
	if (bitsInCommon(status, eHGStatusIgnored))		[icons addObject:ignoredImage];
	
	return icons;
}

+ (NSImage*) compositeRowOfIcons:(NSArray*)icons withOverlap:(CGFloat)overlap
{
	CGFloat hsize = ICON_SIZE + ceil(ICON_SIZE * ([icons count] - 1)/overlap);
	NSImage* combinedImage = [[NSImage alloc] initWithSize:NSMakeSize(hsize,  ICON_SIZE)];
	NSRect imageFrame = NSMakeRect(0, 0, ICON_SIZE, ICON_SIZE);
	[combinedImage lockFocus];
	for (NSImage* icon in icons)
	{
		[icon compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver fraction:1.0];
		imageFrame.origin.x += ICON_SIZE / overlap;
	}
	[combinedImage unlockFocus];
	return combinedImage;
}

- (NSImage*) combinedIconImage
{
	static NSMutableDictionary* cachedIcons = nil;
	if (!cachedIcons)
		cachedIcons = [[NSMutableDictionary alloc] init];
	NSNumber* theKey = [NSNumber numberWithInt:[self hgStatus]];

	NSImage* cached = [cachedIcons objectForKey:theKey];
	if (cached)
		return cached;
	
	NSArray* icons = [FSNodeInfo notableIconImagesForStatus:[self hgStatus] isDirectory:[self isDirectory]];
	NSImage* combinedImage = [FSNodeInfo compositeRowOfIcons:icons withOverlap:IconOverlapCompression];
	[cachedIcons setObject:combinedImage forKey:theKey];
	return combinedImage;
}


- (int) directoryDecorationIconCountForNodeInfo
{
	int iconCount = 0;
	HGStatus status = [self hgStatus];
	if (bitsInCommon(status, eHGStatusMissing))		iconCount++;
	if (bitsInCommon(status, eHGStatusUntracked))	iconCount++;
	if (bitsInCommon(status, eHGStatusAdded))		iconCount++;
	if (bitsInCommon(status, eHGStatusModified))	iconCount++;
	if (bitsInCommon(status, eHGStatusRemoved))		iconCount++;
	if (bitsInCommon(status, eHGStatusUnresolved))	iconCount++;
	if (bitsInCommon(status, eHGStatusResolved))	iconCount++;
	return MAX(iconCount, 1);
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Computed Properties on Trees
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) markNodeAsUncomputed
{
	haveComputedTheProperties = NO;
	maxIconCountOfSubitems_ = notYetComputedIconCount;
	hgStatus = eHGStatusNoStatus;
}

- (FSNodeInfo*) computeProperties
{
	if (childNodes)
	{
		for (id childNodeKey in childNodes)
		{
			FSNodeInfo* childNode = [childNodes objectForKey:childNodeKey];
			if (![childNode haveComputedTheProperties])
				[childNode computeProperties];
			hgStatus = hgStatus | [childNode hgStatus];
		}
		sortedChildNodeKeys = [[childNodes allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	}
	maxIconCountOfSubitems_ = notYetComputedIconCount;
	haveComputedTheProperties = YES;
	return self;
}


// The number of modified, removed, and added files in the whole tree
- (int) computeChangeCount
{
	if (!childNodes)
		return bitsInCommon(hgStatus, eHGStatusCommittable);
	int sum = 0;
	for (id childNodeKey in childNodes)
		sum += [[childNodes objectForKey:childNodeKey] computeChangeCount];
	return sum;
}


// This is lazily computed
- (int)	maxIconCountOfSubitems
{
	if (maxIconCountOfSubitems_ == notYetComputedIconCount)
		for (id childNodeKey in childNodes)
		{
			FSNodeInfo* childNode = [childNodes objectForKey:childNodeKey];
			maxIconCountOfSubitems_ = MAX(maxIconCountOfSubitems_, [childNode directoryDecorationIconCountForNodeInfo]);
		}
	return maxIconCountOfSubitems_;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Tree Construction Trees
// -----------------------------------------------------------------------------------------------------------------------------------------

+ (FSNodeInfo*)	newEmptyTreeRootedAt:(NSString*)theAbsolutePath
{
	return [[FSNodeInfo alloc] initRootNodeAtAbsolutePath:theAbsolutePath];
}


- (FSNodeInfo*) fleshOutTreeWithStatusLines:(NSArray*)hgStatusLines withParentViewer:(FSViewer*)viewer
{
	FSNodeInfo* newRoot = self;
	for (NSString* statusLine in hgStatusLines)
	{
		// If this particular status line is malformed skip this line.
		if ([statusLine length] < 3)
			continue;

		NSString* statusLetter   = [statusLine substringToIndex:1];
		HGStatus  theStatus      = [FSNodeInfo statusEnumFromLetter:statusLetter];
		NSString* statusPath     = [statusLine substringFromIndex:2];
		NSArray*  pathComponents = [statusPath componentsSeparatedByString:@"/"];

		FSNodeInfo* parent = newRoot;

		// If we don't use dictionaries here we can get n^2 behavior, as we search the arrays for each element we just added.
		// This way it's a bit slower but for larger numbers of files in a directory it works much better using a dictionary.
		for (NSString* partName in pathComponents)
		{
			NSMutableDictionary* theChildNodes = [parent childNodes];
			if (!theChildNodes)
			{
				NSMutableDictionary* newChildNodes = [[NSMutableDictionary alloc] init];
				[parent setChildNodes:newChildNodes];
				theChildNodes = newChildNodes;
			}
				
			FSNodeInfo* childNode = [theChildNodes objectForKey:partName];
			[parent markNodeAsUncomputed];
			if (childNode)
			{
				parent = childNode;
			}
			else
			{
				FSNodeInfo* newChild = [[FSNodeInfo alloc] initNewWithParent:parent atRelativePath:partName withParentViewer:viewer];
				[theChildNodes setObject:newChild forKey:partName];
				parent = newChild;
			}
		}
		[parent setHgStatusAdditively:theStatus];
	}
	
	[newRoot computeProperties];
	return newRoot;
}


- (FSNodeInfo*) deepCopyAndDirtify
{
	FSNodeInfo* copiedNode = [[FSNodeInfo alloc]initWithNode:self];
	[copiedNode setHgStatus:unionBits([copiedNode hgStatus], eHGStatusDirty)];
	[[copiedNode childNodes] removeAllObjects];
	NSEnumerator* enumerator = [[self childNodes] objectEnumerator];
	FSNodeInfo* childNode = [enumerator nextObject];
	while (childNode)
	{
		[[copiedNode childNodes] setObject:[childNode deepCopyAndDirtify] forKey:[childNode relativePathComponent]];
		childNode = [enumerator nextObject];
	}
	return copiedNode;
}


- (FSNodeInfo*) shallowTreeCopyMarkingPathsDirty:(NSArray*)theAbsolutePaths
{
	NSString* repositoryRootPath = absolutePath;
	FSNodeInfo* newRoot = [[FSNodeInfo alloc] initWithNode:self];
	for (NSString* theAbsolutePath in theAbsolutePaths)
	{
		NSString* theRelativePath = pathDifference(repositoryRootPath, theAbsolutePath);
		
		// If we have a relative path which is the main repository path or other weirdness fully regenerate things.
		if ([theRelativePath length] <= 0)
			return nil;
		NSArray*  pathComponents = [theRelativePath componentsSeparatedByString:@"/"];
		BOOL done = NO;
		FSNodeInfo* node   = newRoot;
		FSNodeInfo* parent = nil;
		for (NSString* component in pathComponents)
		{
			if (IsEmpty(component))
				break;
			FSNodeInfo* copiedNode = [node haveComputedTheProperties] ? [[FSNodeInfo alloc] initWithNode:node] : node;	// If we have already copied the node we don't need to copy it again
			[[parent childNodes] setObject:copiedNode forKey:[copiedNode relativePathComponent]];
			
			FSNodeInfo* childNode = [[copiedNode childNodes] objectForKey:component];
			if (!childNode)
				{ done = YES; break;}
			parent = copiedNode;
			node = childNode;
		}
		if (done)
			continue;

		// We have arrived at the place we should do a deep copy and dirtify of the tree
		[[parent childNodes] setObject:[node deepCopyAndDirtify] forKey:[node relativePathComponent]];
	}
	[newRoot computeProperties];
	return newRoot;
}


// We basically make a complete copy of the tree but share the nodes which are still the same. Thus if in a forest only one of the
// leaves changes we need to only duplicate and modify the nodes on the way from the leaf back up to the root of the tree. The
// rest of the nodes are all shared.
- (FSNodeInfo*) shallowTreeCopyRemoving:(NSArray*)theAbsolutePaths
{
	NSString* repositoryRootPath = absolutePath;
	FSNodeInfo* newRoot = [[FSNodeInfo alloc] initWithNode:self];
	for (NSString* theAbsolutePath in theAbsolutePaths)
	{
		NSString* theRelativePath = pathDifference(repositoryRootPath, theAbsolutePath);
		
		// If we have a relative path which is the main repository path or other weirdness fully regenerate things.
		if ([theRelativePath length] <= 0)
			return nil;
		NSArray*  pathComponents = [theRelativePath componentsSeparatedByString:@"/"];
		BOOL done = NO;
		FSNodeInfo* node   = newRoot;
		FSNodeInfo* parent = nil;
		NSMutableArray* parentChain = [[NSMutableArray alloc] init];	// The stack of parents as we drill down
		for (NSString* component in pathComponents)
		{
			if (IsEmpty(component))
				break;
			FSNodeInfo* copiedNode = [node haveComputedTheProperties] ? [[FSNodeInfo alloc] initWithNode:node] : node;	// If we have already copied the node we don't need to copy it again
			[[parent childNodes] setObject:copiedNode forKey:[copiedNode relativePathComponent]];

			FSNodeInfo* childNode = [[copiedNode childNodes] objectForKey:component];
			if (!childNode)
				{ done = YES; break;}
			parent = copiedNode;
			node = childNode;
			[parentChain addObject:parent];
		}
		if (done)
			continue;
		
		// We have arrived at the place we should prune the tree
		[[parent childNodes] removeObjectForKey:[node relativePathComponent]];
		
		// We need to prune directories which only contained this one path and are now empty
		FSNodeInfo* folder = [parentChain popLast];
		while (folder && [[folder childNodes] count] == 0)
		{
			FSNodeInfo* parentOfFolder = [parentChain popLast];
			[[parentOfFolder childNodes] removeObjectForKey:[folder relativePathComponent]];
			folder = parentOfFolder;
		}
	}
	[newRoot computeProperties];
	return newRoot;
}



- (NSString*) description
{
	return fstr(@"FSNodeInfo: %@:%@, status = %d", relativePathComponent, absolutePath, hgStatus);
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Flat List Construction
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) addAllLeafNodes:(NSMutableArray*)flatNodes withStatus:(HGStatus)status
{
	if ([[self sortedChildNodeKeys] count] == 0 && bitsInCommon(status, hgStatus))
	{
		[flatNodes addObject:self];
		return;
	}
	for (NSString* key in [self sortedChildNodeKeys])
		[[childNodes objectForKey:key] addAllLeafNodes:flatNodes withStatus:status];
}

- (NSArray*) generateFlatLeafNodeListWithStatus:(HGStatus)status
{
	NSMutableArray* nodeList = [[NSMutableArray alloc]init];
	[self addAllLeafNodes:nodeList withStatus:status];
	return nodeList;
}	





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Preview support
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSImage*) iconImageForPreview { return [NSWorkspace iconImageOfSize:NSMakeSize(128,128) forPath:[self absolutePath]]; }

static NSString* stringFromFileSize(NSInteger theSize)
{
	float floatSize = theSize;
	if (theSize<1023)
		return fstr(@"%i bytes\n",theSize);
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return fstr(@"%1.1f KB\n",floatSize);
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return fstr(@"%1.1f MB\n",floatSize);
	floatSize = floatSize / 1024;
	
	return fstr(@"%1.1f GB\n",floatSize);
}

static NSString* stringFromItemCount(NSInteger theCount)
{
	if (theCount == 1)
		return @"1 item\n";
	return fstr( @"%d items\n", theCount);
}

- (NSAttributedString*) attributedInspectorStringForFSNode
{
	static NSDateFormatter* dateFormatter = nil;
	if (!dateFormatter)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	}
	
	NSMutableAttributedString* attrString = [NSMutableAttributedString string:fstr( @"%@\n", [self lastPathComponent]) withAttributes:smallCenteredSystemFontAttributes];

	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSDictionary* fileAttributes = [fileManager attributesOfItemAtPath:absolutePath error:nil];
	
	if (![self isDirectory])
		[attrString appendAttributedString: [NSAttributedString string:stringFromFileSize([fileAttributes fileSize]) withAttributes:smallCenteredSystemFontAttributes]];
	else
		[attrString appendAttributedString: [NSAttributedString string:stringFromItemCount([sortedChildNodeKeys count]) withAttributes:smallCenteredSystemFontAttributes]];
	
	NSString* dateModifiedString = [dateFormatter stringFromDate:[fileAttributes fileModificationDate]];
	[attrString appendAttributedString: [NSAttributedString string:@"Mod. " withAttributes:smallBoldCenteredSystemFontAttributes]];
	[attrString appendAttributedString: [NSAttributedString string:fstr( @"%@\n", dateModifiedString) withAttributes:smallCenteredSystemFontAttributes]];

	NSString* dateCreatedString = [dateFormatter stringFromDate:[fileAttributes fileCreationDate]];
	[attrString appendAttributedString: [NSAttributedString string:@"Crd. " withAttributes:smallBoldCenteredSystemFontAttributes]];
	[attrString appendAttributedString: [NSAttributedString string:fstr( @"%@\n", dateCreatedString) withAttributes:smallCenteredSystemFontAttributes]];
	
	return attrString;
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------

NSArray* pathsOfFSNodes(NSArray* nodes)
{
	NSMutableArray* paths = [[NSMutableArray alloc]init];
	for (FSNodeInfo* node in nodes)
		[paths addObject:[node absolutePath]];
	return paths;
}
