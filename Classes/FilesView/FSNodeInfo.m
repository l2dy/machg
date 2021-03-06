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

@synthesize parentFSViewer = parentFSViewer;
@synthesize relativePathComponent = relativePathComponent;
@synthesize absolutePath = absolutePath;
@synthesize childNodes = childNodes;
@synthesize sortedChildNodeKeys = sortedChildNodeKeys;
@synthesize haveComputedTheProperties = haveComputedTheProperties;
@synthesize hgStatus = hgStatus;


// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Queries
// ------------------------------------------------------------------------------------

// Given a node we have its absolute path and we can query if it is a link, readable, a directory, etc....
- (BOOL) isLink
{
	NSFileManager* fileManager = NSFileManager.defaultManager;
	NSDictionary* fileAttributes = [fileManager attributesOfItemAtPath:absolutePath error:nil];
	return [fileAttributes.fileType isEqualToString:NSFileTypeSymbolicLink];
}

- (BOOL) isDirectory
{
	if (childNodes.count	> 0)
		return YES;
	BOOL isDir = NO;
	BOOL exists = [NSFileManager.defaultManager fileExistsAtPath:absolutePath isDirectory:&isDir];
	return exists && isDir;
}

- (BOOL) isFile
{
	if (childNodes.count	> 0)
		return NO;
	BOOL isDir = NO;
	BOOL exists = [NSFileManager.defaultManager fileExistsAtPath:absolutePath isDirectory:&isDir];
	return exists && !isDir;
}


- (BOOL) isVisible
{
	// Make this as sophisticated for example to hide more files you don't think the user should see!
	NSString* lastPathComponent = self.lastPathComponent;
	return (lastPathComponent.length ? ([lastPathComponent characterAtIndex:0]!='.') : NO);
}

- (BOOL)		isDirty				{ return bitsInCommon(hgStatus, eHGStatusDirty); }
- (BOOL)		isReadable			{ return [NSFileManager.defaultManager isReadableFileAtPath:absolutePath]; }
- (NSString*)	fsType				{ return self.isDirectory ? @"Directory" : @"Non-Directory"; }
- (NSString*)	lastPathComponent	{ return relativePathComponent.lastPathComponent; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Accessors
// ------------------------------------------------------------------------------------

- (NSInteger)   childNodeCount						{ return self.sortedChildNodeKeys.count; }
- (FSNodeInfo*) childNodeAtIndex:(NSInteger)index	{ return [self.childNodes objectForKey:[self.sortedChildNodeKeys objectAtIndex:index]]; }

// This method must be called on theRoot node.
- (FSNodeInfo*) nodeForPathFromRoot:(NSString*)thePath
{
	NSString* theRelativePath = pathDifference(self.absolutePath, thePath);
	if (IsEmpty(theRelativePath))
		return [self.absolutePath isEqualToString:thePath] ? self : nil;
	NSArray* thePathComponents = theRelativePath.pathComponents;
	FSNodeInfo* node = self;
	for (NSString* pathPath in thePathComponents)
		node = node.childNodes[pathPath];
	return node;
}

// This method must be called on theRoot node.
- (BOOL) getRow:(NSInteger*)row andColumn:(NSInteger*)column forNode:(FSNodeInfo*)goalNode
{
	if (row == nil || column == nil || goalNode == nil)
		return NO;

	*column = -1;
	*row = 0;
	NSString* thePath = goalNode.absolutePath;
	NSString* theRelativePath = pathDifference(self.absolutePath, thePath);
	if (IsEmpty(theRelativePath))
		return NO;
	
	NSArray* thePathComponents = theRelativePath.pathComponents;
	FSNodeInfo* node = self;
	FSNodeInfo* childNode = self;
	for (NSString* pathPath in thePathComponents)
	{
		node = childNode;
		childNode = node.childNodes[pathPath];
		(*column)++;
	}
	if (!childNode)
		return NO;
	*row = [node.sortedChildNodeKeys indexOfObject:thePathComponents.lastObject];
	return (*row != NSNotFound);
}




// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Tree Construction Nodes
// ------------------------------------------------------------------------------------

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
	self = [super init];
	if (!self)
		return nil;
	relativePathComponent = theAbsolutePath;
	absolutePath = theAbsolutePath;
	childNodes = nil;
	sortedChildNodeKeys = nil;
	hgStatus = eHGStatusNoStatus;
	return self;
}

- (FSNodeInfo*) initNewWithParent:(FSNodeInfo*)parent atRelativePath:(NSString*)path withParentViewer:(FSViewer*)viewer
{
	self = [super init];
	if (!self)
		return nil;
	parentFSViewer = viewer;
	relativePathComponent = path;
	absolutePath = [parent.absolutePath stringByAppendingPathComponent:relativePathComponent];
	childNodes = nil;
	sortedChildNodeKeys = nil;
	haveComputedTheProperties = NO;
	hgStatus = eHGStatusNoStatus;
	maxIconCountOfSubitems_ = notYetComputedIconCount;
	return self;
}

- (FSNodeInfo*) initWithNodeEnvironment:(FSNodeInfo*)node
{
	self = [super init];
	if (!self)
		return nil;
	parentFSViewer = node.parentFSViewer;
	relativePathComponent = node.relativePathComponent;
	absolutePath = node.absolutePath;
	childNodes = nil;
	sortedChildNodeKeys = nil;
	haveComputedTheProperties = NO;
	hgStatus = eHGStatusNoStatus;
	maxIconCountOfSubitems_ = notYetComputedIconCount;
	return self;
}

- (FSNodeInfo*) initWithNode:(FSNodeInfo*)node
{
	self = [self initWithNodeEnvironment:node];
	if (!self)
		return nil;
	childNodes = [node.childNodes mutableCopy];
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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Icons for Nodes
// ------------------------------------------------------------------------------------

- (NSImage*) iconImageOfSize:(NSSize)size
{    
	NSString* path = self.absolutePath;
	NSString* defaultImageName = self.isDirectory ? NSImageNameFolder : @"FSIconImage-Default";
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

	if (bitsInCommon(status, eHGStatusDirty))		[icons addObject:blankImage];
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
	NSInteger adjustedIconCount = MAX(icons.count - 1, 0);
	CGFloat hsize = ceil(ICON_SIZE * (1 + adjustedIconCount / overlap));
	NSImage* combinedImage = [[NSImage alloc] initWithSize:NSMakeSize(hsize,  ICON_SIZE)];
	NSRect imageFrame = NSMakeRect(0, 0, ICON_SIZE, ICON_SIZE);
	[combinedImage lockFocus];
	for (NSImage* icon in icons)
	{
		[icon drawAtPoint:imageFrame.origin fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
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
	NSNumber* theKey = [NSNumber numberWithInt:self.hgStatus];

	NSImage* cached = cachedIcons[theKey];
	if (cached)
		return cached;
	
	NSArray* icons = [FSNodeInfo notableIconImagesForStatus:self.hgStatus isDirectory:self.isDirectory];
	NSImage* combinedImage = [FSNodeInfo compositeRowOfIcons:icons withOverlap:IconOverlapCompression];
	cachedIcons[theKey] = combinedImage;
	return combinedImage;
}


- (int) directoryDecorationIconCountForNodeInfo
{
	int iconCount = 0;
	HGStatus status = self.hgStatus;
	if (bitsInCommon(status, eHGStatusMissing))		iconCount++;
	if (bitsInCommon(status, eHGStatusUntracked))	iconCount++;
	if (bitsInCommon(status, eHGStatusAdded))		iconCount++;
	if (bitsInCommon(status, eHGStatusModified))	iconCount++;
	if (bitsInCommon(status, eHGStatusRemoved))		iconCount++;
	if (bitsInCommon(status, eHGStatusUnresolved))	iconCount++;
	if (bitsInCommon(status, eHGStatusResolved))	iconCount++;
	return MAX(iconCount, 1);
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Computed Properties on Trees
// ------------------------------------------------------------------------------------

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
			FSNodeInfo* childNode = childNodes[childNodeKey];
			if (!childNode.haveComputedTheProperties)
				[childNode computeProperties];
			hgStatus = hgStatus | childNode.hgStatus;
		}
		sortedChildNodeKeys = [childNodes.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
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
		sum += [childNodes[childNodeKey] computeChangeCount];
	return sum;
}


// This is lazily computed
- (int)	maxIconCountOfSubitems
{
	if (maxIconCountOfSubitems_ == notYetComputedIconCount)
		for (id childNodeKey in childNodes)
		{
			FSNodeInfo* childNode = childNodes[childNodeKey];
			maxIconCountOfSubitems_ = MAX(maxIconCountOfSubitems_, childNode.directoryDecorationIconCountForNodeInfo);
		}
	return maxIconCountOfSubitems_;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Tree Construction Trees
// ------------------------------------------------------------------------------------

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
		if (statusLine.length < 3)
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
			NSMutableDictionary* theChildNodes = parent.childNodes;
			if (!theChildNodes)
			{
				NSMutableDictionary* newChildNodes = [[NSMutableDictionary alloc] init];
				parent.childNodes = newChildNodes;
				theChildNodes = newChildNodes;
			}
				
			FSNodeInfo* childNode = theChildNodes[partName];
			[parent markNodeAsUncomputed];
			if (childNode)
			{
				parent = childNode;
			}
			else
			{
				FSNodeInfo* newChild = [[FSNodeInfo alloc] initNewWithParent:parent atRelativePath:partName withParentViewer:viewer];
				theChildNodes[partName] = newChild;
				parent = newChild;
			}
		}
		parent.hgStatusAdditively = theStatus;
	}
	
	[newRoot computeProperties];
	return newRoot;
}


- (FSNodeInfo*) deepCopyAndDirtify
{
	FSNodeInfo* copiedNode = [[FSNodeInfo alloc]initWithNode:self];
	copiedNode.hgStatus = unionBits(copiedNode.hgStatus, eHGStatusDirty);
	[copiedNode.childNodes removeAllObjects];
	for (FSNodeInfo* childNode in self.childNodes.objectEnumerator)
		[copiedNode childNodes][childNode.relativePathComponent] = childNode.deepCopyAndDirtify;
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
		if (IsEmpty(theRelativePath))
			return nil;
		NSArray*  pathComponents = [theRelativePath componentsSeparatedByString:@"/"];
		BOOL done = NO;
		FSNodeInfo* node   = newRoot;
		FSNodeInfo* parent = nil;
		for (NSString* component in pathComponents)
		{
			if (IsEmpty(component))
				break;
			FSNodeInfo* copiedNode = node.haveComputedTheProperties ? [[FSNodeInfo alloc] initWithNode:node] : node;	// If we have already copied the node we don't need to copy it again
			[parent childNodes][copiedNode.relativePathComponent] = copiedNode;
			
			FSNodeInfo* childNode = copiedNode.childNodes[component];
			if (!childNode)
				{ done = YES; break;}
			parent = copiedNode;
			node = childNode;
		}
		if (done)
			continue;

		// We have arrived at the place we should do a deep copy and dirtify of the tree
		[parent childNodes][node.relativePathComponent] = node.deepCopyAndDirtify;
	}
	[newRoot computeProperties];
	return newRoot;
}


// We basically make a complete copy of the tree but share the nodes which are still the same. Thus if in a forest only one of the
// leaves changes we need to only duplicate and modify the nodes on the way from the leaf back up to the root of the tree. The
// rest of the nodes are all shared.
- (FSNodeInfo*) copyRemoving:(NSArray*)theRelativeComponentPaths
{
	// The basic idea is to progress through both lists of exisiting child node keys and first path components (prune keys) at the
	// same time. These lists have been alphabetized to be in the same order (under localized case insensitve compare). Any
	// existing child keys which are not being pruned are copied verbatim, and for any child keys matching prune keys we collect
	// up the subset of paths to be pruned with the same key and then recursively create a new pruned node for that child. 
	NSInteger i = 0;
	NSInteger j = 0;
	NSMutableDictionary* newChildNodes = [[NSMutableDictionary alloc] init];
	while (i < self.sortedChildNodeKeys.count && j < theRelativeComponentPaths.count)
	{
		NSString* existingKey = self.sortedChildNodeKeys[i];
		NSArray* componentPath = theRelativeComponentPaths[j];
		NSString* pruneKey = componentPath.firstObject;
		NSComparisonResult comp = [existingKey localizedCaseInsensitiveCompare:pruneKey];
		
		// If the existing key is different then the key to remove then keep this child node
		if (comp == NSOrderedAscending)
		{
			newChildNodes[existingKey] = self.childNodes[existingKey];
			i++;
			continue;
		}

		// If the key to remove doesn't appear in the child nodes than we are done.
		if (comp == NSOrderedDescending)
		{
			j++;
			continue;
		}

		// If the path to remove doesn't have any further path components than we are prunning this child node and all it's children
		if (componentPath.count == 1)
		{
			i++;
			j++;
			continue;
		}

		if (![existingKey isEqualToString:pruneKey])
		{
			DebugLog(@"bad string match case in tree construciton");
		}
		
		NSMutableArray* subsetOfPathsToRemove = [[NSMutableArray alloc] init];
		while (j < theRelativeComponentPaths.count)
		{
			componentPath = theRelativeComponentPaths[j];
			if (![existingKey isEqualToString:componentPath.firstObject])
				break;
			NSArray* childComponentPath = componentPath.arrayByRemovingFirst;
			[subsetOfPathsToRemove addObject:childComponentPath];
			j++;
		}
		FSNodeInfo* newPrunedChild = [self.childNodes[existingKey] copyRemoving:subsetOfPathsToRemove];
		if (newPrunedChild)
			newChildNodes[existingKey] = newPrunedChild;
		i++;
	}
	
	// If there are remaining existing children nodes than add these
	while (i < self.sortedChildNodeKeys.count)
	{
		NSString* existingKey = self.sortedChildNodeKeys[i];
		newChildNodes[existingKey] = self.childNodes[existingKey];
		i++;
	}
	
	if (IsEmpty(newChildNodes))
		return nil;
	FSNodeInfo* newPrunedCopy = [[FSNodeInfo alloc] initWithNodeEnvironment:self];
	newPrunedCopy.childNodes = newChildNodes;
	return newPrunedCopy;
}


// We basically make a complete copy of the tree but share the nodes which are still the same. Thus if in a forest only one of the
// leaves changes we need to only duplicate and modify the nodes on the way from the leaf back up to the root of the tree. The
// rest of the nodes are all shared.
- (FSNodeInfo*) shallowTreeCopyRemoving:(NSArray*)theAbsolutePaths
{
	NSString* repositoryRootPath = absolutePath;
	NSMutableArray* theRelativeComponentPaths = [[NSMutableArray alloc] init];
	NSArray* theSortedAbsolutePaths = [theAbsolutePaths sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	for (NSString* theAbsolutePath in theSortedAbsolutePaths)
	{
		NSString* theRelativePath = pathDifference(repositoryRootPath, theAbsolutePath);

		// If we have a relative path which is the main repository path or other weirdness fully regenerate things.
		if (IsEmpty(theRelativePath))
			return nil;
		NSArray* componentsPaths = [[theRelativePath componentsSeparatedByString:@"/"] trimArray];
		[theRelativeComponentPaths addObject:componentsPaths];
	}
	
	FSNodeInfo* newRoot = [self copyRemoving:theRelativeComponentPaths];
	[newRoot computeProperties];
	return newRoot;
}


- (NSString*) description
{
	return fstr(@"FSNodeInfo: %@:%@, status = %d", relativePathComponent, absolutePath, hgStatus);
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Flat List Construction
// ------------------------------------------------------------------------------------

- (void) addAllLeafNodes:(NSMutableArray*)flatNodes withStatus:(HGStatus)status
{
	if (self.sortedChildNodeKeys.count == 0 && bitsInCommon(status, hgStatus))
	{
		[flatNodes addObject:self];
		return;
	}
	for (NSString* key in self.sortedChildNodeKeys)
		[childNodes[key] addAllLeafNodes:flatNodes withStatus:status];
}

- (NSArray*) generateFlatLeafNodeListWithStatus:(HGStatus)status
{
	NSMutableArray* nodeList = [[NSMutableArray alloc]init];
	[self addAllLeafNodes:nodeList withStatus:status];
	return nodeList;
}	





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Preview support
// ------------------------------------------------------------------------------------

- (NSImage*) iconImageForPreview { return [NSWorkspace iconImageOfSize:NSMakeSize(128,128) forPath:self.absolutePath]; }

static NSString* stringFromFileSize(NSInteger theSize)
{
	float floatSize = theSize;
	if (theSize<1023)
		return fstr(@"%li bytes\n",theSize);
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
	return fstr( @"%ld items\n", theCount);
}

- (NSAttributedString*) attributedInspectorStringForFSNode
{
	static NSDateFormatter* dateFormatter = nil;
	if (!dateFormatter)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateStyle = NSDateFormatterShortStyle;
		dateFormatter.timeStyle = NSDateFormatterShortStyle;
	}
	
	NSMutableAttributedString* attrString = [NSMutableAttributedString string:fstr( @"%@\n", self.lastPathComponent) withAttributes:smallCenteredSystemFontAttributes];

	NSFileManager* fileManager = NSFileManager.defaultManager;
	NSDictionary* fileAttributes = [fileManager attributesOfItemAtPath:absolutePath error:nil];
	
	if (!self.isDirectory)
		[attrString appendAttributedString: [NSAttributedString string:stringFromFileSize(fileAttributes.fileSize) withAttributes:smallCenteredSystemFontAttributes]];
	else
		[attrString appendAttributedString: [NSAttributedString string:stringFromItemCount(sortedChildNodeKeys.count) withAttributes:smallCenteredSystemFontAttributes]];
	
	NSString* dateModifiedString = [dateFormatter stringFromDate:fileAttributes.fileModificationDate];
	[attrString appendAttributedString: [NSAttributedString string:@"Mod. " withAttributes:smallBoldCenteredSystemFontAttributes]];
	[attrString appendAttributedString: [NSAttributedString string:fstr( @"%@\n", dateModifiedString) withAttributes:smallCenteredSystemFontAttributes]];

	NSString* dateCreatedString = [dateFormatter stringFromDate:fileAttributes.fileCreationDate];
	[attrString appendAttributedString: [NSAttributedString string:@"Crd. " withAttributes:smallBoldCenteredSystemFontAttributes]];
	[attrString appendAttributedString: [NSAttributedString string:fstr( @"%@\n", dateCreatedString) withAttributes:smallCenteredSystemFontAttributes]];
	
	return attrString;
}

@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Utilities
// ------------------------------------------------------------------------------------

NSArray* pathsOfFSNodes(NSArray* nodes)
{
	NSMutableArray* paths = [[NSMutableArray alloc]init];
	for (FSNodeInfo* node in nodes)
		[paths addObject:node.absolutePath];
	return paths;
}
