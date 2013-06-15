//
//  SidebarNode.m
//
//  Original version created by Matteo Bertozzi on 3/8/09.
//  Copyright 2009 Matteo Bertozzi. All rights reserved.
//  Extensive modifications made by Jason Harris 29/11/09.
//  Copyright 2009 Jason Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "SidebarNode.h"
#import "TaskExecutions.h"
#import "AppController.h"
#import "NSString+SymlinksAndAliases.h"


@interface SidebarNode (PrivateAPI)
- (void) checkReportedRepositoryIdentity:(NSNotification*)notification;
@end


@implementation SidebarNode

@synthesize nodeKind = nodeKind;
@synthesize children = children;
@synthesize parent = parent;
@synthesize shortName = shortName;
@synthesize icon = icon;
@synthesize isExpanded = isExpanded;
@synthesize path = path;
@synthesize recentPullConnection = recentPullConnection;
@synthesize recentPushConnection = recentPushConnection;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (id) init
{
	if ((self = [super init]))
	{
		children	= nil;
		parent		= nil;
		shortName	= nil;
		path		= nil;
		icon		= nil;
		isExpanded	= NO;
		recentPullConnection = nil;
		recentPushConnection = nil;
	}
	
	return self;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Constructors
// ------------------------------------------------------------------------------------

+ (SidebarNode*) sectionNodeWithCaption:(NSString*)caption { return [SidebarNode nodeWithCaption:caption  path:nil icon:nil  nodeKind:kSidebarNodeKindSection]; }
+ (SidebarNode*) nodeForLocalURL:(NSString*)path
{
	NSString* name = [[NSFileManager defaultManager] displayNameAtPath:path];
	return [SidebarNode nodeWithCaption:name  forLocalPath:path];
}

+ (SidebarNode*) nodeWithCaption:(NSString*)cap  forLocalPath:(NSString*)path
{
	NSImage* theIcon = [[NSWorkspace sharedWorkspace] iconForFile:path];
	return [SidebarNode nodeWithCaption:cap path:path icon:theIcon nodeKind:kSidebarNodeKindLocalRepositoryRef];
}
+ (SidebarNode*) nodeWithCaption:(NSString*)cap  forServerPath:(NSString*)path
{
	NSImage* theIcon = [NSImage imageNamed:NSImageNameNetwork];
	return [SidebarNode nodeWithCaption:cap path:path icon:theIcon nodeKind:kSidebarNodeKindServerRepositoryRef];
}

+ (SidebarNode*) nodeWithCaption:(NSString*)cap  path:(NSString*)thePath icon:(NSImage*)icn  nodeKind:(SidebarNodeKind)type
{
	// Create and Setup Node
	SidebarNode* node = [[SidebarNode alloc] init];
	[node setNodeKind:type];
	[node setShortName:cap];
	[node setPath:trimString(thePath)];
	[node setParent:nil];
	[node setIcon:icn];
	return node;
}

// Duplicate a node but don't copy the immutable bits, so the size of the copy is smallish.
- (SidebarNode*) copyNode
{
	SidebarNode* newNode		= [[SidebarNode alloc]init];
	newNode->nodeKind			= nodeKind;
	newNode->shortName			= shortName;
	newNode->path				= path;
	newNode->icon				= icon;
	newNode->isExpanded			= isExpanded;
	newNode->recentPullConnection = recentPullConnection;
	newNode->recentPushConnection = recentPushConnection;
	return newNode;
}

// Duplicate a tree but don't copy the immutable bits, so the size of the copy is smallish.
- (SidebarNode*) copyNodeTree
{
	SidebarNode* newNode = [self copyNode];
	if (children)
	{
		newNode->children = [[NSMutableArray alloc]init];
		for (SidebarNode* node in children)
			[newNode->children addObject:[node copyNodeTree]];
		for (SidebarNode* node in newNode->children)
			[node setParent:newNode];
	}
	return newNode;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Setters and Accessors
// ------------------------------------------------------------------------------------

static inline NSInteger rangeCheckIndex(NSInteger index, NSInteger count)	{ return (index >= 0 && index <= count) ? index : count; }

- (void) setShortName:(NSString*)name	{ shortName = name; }

- (void) addChild:(SidebarNode*)node								{ if (!children) children = [[NSMutableArray alloc]init];  [children addObject:node];														[node setParent:self]; }
- (void) insertChild:(SidebarNode*)node atIndex:(NSUInteger)index	{ if (!children) children = [[NSMutableArray alloc]init];  [children insertObject:node atIndex:rangeCheckIndex(index, [children count])];	[node setParent:self]; }
- (void) removeChild:(SidebarNode*)node				{ [children removeObject:node]; }
- (NSInteger) indexOfChildNode:(SidebarNode*)node	{ return [children indexOfObject:node]; }
- (SidebarNode*) childNodeAtIndex:(int)index		{ return children[index]; }
- (NSUInteger) numberOfChildren						{ return [children count]; }
- (NSInteger) level									{ return parent ? (1 + [parent level]) : -1; }	// Should be the same as NSOutlineView::levelForItem:

- (BOOL) isExistentLocalRepositoryRef				{ return [self isLocalRepositoryRef] && pathIsExistentDirectory(path); }
- (BOOL) isMissingLocalRepositoryRef				{ return [self isLocalRepositoryRef] && !repositoryExistsAtPath(path); }
- (BOOL) isLocalRepositoryRef						{ return (nodeKind == kSidebarNodeKindLocalRepositoryRef); }
- (BOOL) isServerRepositoryRef						{ return (nodeKind == kSidebarNodeKindServerRepositoryRef); }
- (BOOL) isSectionNode								{ return (nodeKind == kSidebarNodeKindSection); }
- (BOOL) isTopLevelSectionNode						{ return [self isSectionNode] && ([self level] <= 0); }
- (BOOL) isDraggable								{ return ![self isSectionNode]; }
- (BOOL) isRepositoryRef							{ return [self isLocalRepositoryRef] || [self isServerRepositoryRef]; }



- (NSMutableArray*) allChildrenAccumulate:(NSMutableArray*)all
{
	[all addObjectsFromArray:children];
	for (SidebarNode* child in children)
		[child allChildrenAccumulate:all];
	return all;
}
- (NSArray*) allChildren
{
	NSMutableArray* all = [[NSMutableArray alloc] init];
	return [self allChildrenAccumulate:all];
}


- (NSAttributedString*) attributedStringForNodeAndSelected:(BOOL)selected
{
	static NSShadow* noShadow = nil;
	static NSShadow* shadow   = nil;
	if (!shadow)
	{
		noShadow = [[NSShadow alloc] init];
		shadow   = [[NSShadow alloc] init];
		[shadow setShadowColor:[NSColor colorWithDeviceWhite:1 alpha:0.7]];
		[shadow setShadowOffset:NSMakeSize(0,-1)];
		[shadow setShadowBlurRadius:1];
	}
	
	NSMutableDictionary* attributesToApply = [standardSidebarFontAttributes mutableCopy];
	if (selected)
		attributesToApply[NSForegroundColorAttributeName] = [NSColor whiteColor];
	if ([self isVirginRepository])
		attributesToApply[NSForegroundColorAttributeName] = selected ? virginSidebarSelectedColor : virginSidebarColor;
	if ([self isServerRepositoryRef])
		attributesToApply[NSObliquenessAttributeName] = @0.15f;
	if ([self isMissingLocalRepositoryRef])
		attributesToApply[NSForegroundColorAttributeName] = selected ? missingSidebarSelectedColor : missingSidebarColor;
	if ([self isSectionNode])
	{
		attributesToApply[NSForegroundColorAttributeName] = selected ? [NSColor whiteColor] : [NSColor colorWithDeviceWhite:0.5 alpha:1.0];
		attributesToApply[NSFontAttributeName] = [NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]];
		attributesToApply[NSShadowAttributeName] = selected ? noShadow : shadow;
	}
	return [NSAttributedString string:shortName withAttributes:attributesToApply];
}


- (BOOL) isEqual:(id)object	{ return [SidebarNode class] == [object class] && path == [object path] && shortName == [object shortName] && nodeKind == [object nodeKind]; }

- (NSInteger) nodeDepth
{
	SidebarNode* trackParent = self;
	NSInteger i = 0;
	for (; [trackParent parent] != nil; i++)
		trackParent = [trackParent parent];
	return i;
}

- (NSString*) description
{
	NSMutableString* part = [[NSMutableString alloc]init];
	NSInteger depth = [self nodeDepth];
	for (NSInteger i = 0; i < depth; i++)
		[part appendString:@"   "];
	[part appendFormat:@"<%@{ caption = %@, path = %@, id = %@ }\n", [self className], shortName, path, nonNil([self repositoryIdentity])];
	for (SidebarNode* node in children)
		[part appendString:[node description]];
	if (recentPushConnection)
		[part appendFormat:@"recentPushConnection: %@\n", [self recentPushConnection]];
	if (recentPullConnection)
		[part appendFormat:@"recentPullConnection: %@\n", [self recentPullConnection]];
	
	return part;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Decorated Paths
// ------------------------------------------------------------------------------------

- (NSString*) fullURLPath
{
	if (![self isServerRepositoryRef])
		return path;
	return FullServerURL(path, eAllPasswordsAreVisible);
}

- (NSString*) pathHidingAnyPassword
{
	if (![self isServerRepositoryRef])
		return path;
	return FullServerURL(path, eAllPasswordsAreMangled);
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Saving & Loading
// ------------------------------------------------------------------------------------

// Originally I stored the node kind as a sequential list, however with multiple selections it's nice to have a bitfield, to be
// able to represent the type of multiple sidebar nodes. Thus translate from MacHg's internal use of a new enum bitfield and the
// historical storage of the node kind. 
NSInteger storedNodeTypeFromNodeKind(SidebarNodeKind nodeKind)
{
	switch (nodeKind)
	{
		case kSidebarNodeKindSection:				return 0x01;
		case kSidebarNodeKindFolder:				return 0x02;
		case kSidebarNodeKindLocalRepositoryRef:	return 0x03;
		case kSidebarNodeKindServerRepositoryRef:	return 0x04;
		default:									return 0x00;
	}
}

SidebarNodeKind nodeKindFromStoredNodeType(NSInteger storedType)
{
	switch (storedType)
	{
		case 0x01:	return kSidebarNodeKindSection;
		case 0x02:	return kSidebarNodeKindFolder;
		case 0x03:	return kSidebarNodeKindLocalRepositoryRef;
		case 0x04:	return kSidebarNodeKindServerRepositoryRef;
		default:	return kSidebarNodeKindNone;
	}
}



- (void) encodeWithCoder:(NSCoder*)coder
{
	// We don't include the icon here since it takes up a lot of room. Eg a document with only 8 repositories has a size of 768K
	// if the icons are included and 8K if the are omitted, so we leave the icons out and just reload them. Of course if the
	// files are no longer there then the icon will be different than the original icon.

	[coder encodeInt:storedNodeTypeFromNodeKind(nodeKind) forKey:@"nodeType"];
	[coder encodeObject:children forKey:@"children"];
	[coder encodeObject:shortName forKey:@"caption"];
	[coder encodeBool:isExpanded forKey:@"nodeIsExpanded"];
	[coder encodeObject:path forKey:@"path"];
	[coder encodeObject:recentPushConnection forKey:@"recentPushConnection"];
	[coder encodeObject:recentPullConnection forKey:@"recentPullConnection"];

	NSString* repositoryIdentity = [[[AppController sharedAppController] repositoryIdentityForPath] synchronizedObjectForKey:path];
	if (IsEmpty(repositoryIdentity))
		repositoryIdentity = [self repositoryIdentity];
	if (repositoryIdentity)
		[coder encodeObject:repositoryIdentity forKey:@"repositoryIdentity"];
}


- (id) initWithCoder:(NSCoder*)coder
{
	self = [super init];
	if (!self)
		return nil;

	nodeKind	= nodeKindFromStoredNodeType([coder decodeIntForKey:@"nodeType"]);
	children	= [coder decodeObjectForKey:@"children"];
	shortName	= [coder decodeObjectForKey:@"caption"];
	isExpanded	= [coder decodeBoolForKey:@"nodeIsExpanded"];
	path		= [coder decodeObjectForKey:@"path"];
	recentPushConnection = [coder decodeObjectForKey:@"recentPushConnection"];
	recentPullConnection = [coder decodeObjectForKey:@"recentPullConnection"];

	if ([self isLocalRepositoryRef] && path)
	{
		if ([path length] < PATH_MAX)
		{
			NSString* cachedPath = path;
			path = [path stringByResolvingSymlinksAndAliases];
			if (path)
				path = caseSensitiveFilePath(path);
			else
				path = cachedPath;
		}
		else
			NSRunCriticalAlertPanel(@"Max Path Length exceeded", fstr(@"The maximum path length for the path to the repository root was exceeded. Functionality for this repository could be erratic. The path is", path), @"OK", nil, nil);
	}
	
	if ([self isRepositoryRef] && path)
	{
		NSString* repositoryIdentity = [coder decodeObjectForKey:@"repositoryIdentity"];
		if (repositoryIdentity)
			[[[AppController sharedAppController] repositoryIdentityForPath] synchronizedSetObject:repositoryIdentity forKey:path];
	}

	// Regenerate the icon as above to save space.
	[self refreshNodeIcon];

	return self;
}

- (void) refreshNodeIcon
{
	if ([self isLocalRepositoryRef] && repositoryExistsAtPath(path))
		icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
	else if ([self isLocalRepositoryRef])
		icon = [NSImage imageNamed:@"MissingRepository.png"];
	else if ([self isServerRepositoryRef])
		icon = [NSImage imageNamed:NSImageNameNetwork];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Root Changeset
// ------------------------------------------------------------------------------------

- (NSString*) repositoryIdentity	{ return [[[AppController sharedAppController] repositoryIdentityForPath] synchronizedObjectForKey:path]; }


// Virgin repositories are freshly initialized repositories in mercurial without any commits in them at all. The first commit or
// push to such a repository will "crystalize" the repository in this new state.
- (BOOL) isVirginRepository
{
	static NSString* virginRepository = @"000000000000";
	return [[self repositoryIdentity] isEqualToString:virginRepository];
}

- (BOOL) isCompatibleToNodeInArray:(NSArray*)nodes
{
	for (SidebarNode* node in nodes)
		if ([self isCompatibleTo:node])
			return YES;
	return NO;
}

- (BOOL) isCompatibleTo:(SidebarNode*)other
{
	// If the paths are the same then the servers have to be compatible since they reference the same thing. (This is useful when
	// you can't actually get a repository identity
	if ([trimString([self path]) isEqualToString:trimString([other path])])
		return YES;
	
	NSString* repositoryIdentitySelf  = [self repositoryIdentity];
	NSString* repositoryIdentityOther = [other repositoryIdentity];

	if (repositoryIdentitySelf == nil || repositoryIdentityOther == nil)
		return NO;
	if ([self isVirginRepository] || [other isVirginRepository])
		return YES;
	return [repositoryIdentitySelf isEqualToString:repositoryIdentityOther];
}


- (SidebarNode*) copySubtreeCompatibleTo:(SidebarNode*)comp
{
	BOOL isCompatobleRepo = [self isRepositoryRef] && [self isCompatibleTo:comp];
	if (IsEmpty(children))
		return isCompatobleRepo ? [self copyNode] : nil;

	NSMutableArray* compatibleChildren = [[NSMutableArray alloc]init];
	for (SidebarNode* node in children)
	{
		SidebarNode* subtree = [node copySubtreeCompatibleTo:comp];
		[compatibleChildren addObjectIfNonNil:subtree];
	}
	
	if (!isCompatobleRepo && IsEmpty(compatibleChildren))
		return nil;
	SidebarNode* prunedNode = [self copyNode];
	prunedNode->children = compatibleChildren;
	
	// For the incompatible repository references list them in the selection menu's as section nodes
	if ([self isRepositoryRef] && !isCompatobleRepo)
		[prunedNode setNodeKind:kSidebarNodeKindSection];

	return prunedNode;
}


@end
