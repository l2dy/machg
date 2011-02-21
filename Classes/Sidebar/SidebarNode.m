//
//  SidebarNode.m
//  Sidebar
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

@implementation SidebarNode

@synthesize nodeKind;
@synthesize children;
@synthesize parent;
@synthesize shortName;
@synthesize path;
@synthesize recentConnections;
@synthesize icon;
@synthesize isExpanded;
@synthesize hasPassword;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id) init
{
	if ((self = [super init]))
	{
		children	= nil;
		parent		= nil;
		shortName	= nil;
		path		= nil;
		recentConnections = nil;
		icon		= nil;
		isExpanded	= NO;
		hasPassword = NO;
	}
	
	return self;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Constructors
// -----------------------------------------------------------------------------------------------------------------------------------------

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
	[node setPath:thePath];
	[node setParent:nil];
	[node setIcon:icn];
	[node repositoryIdentity];
	return node;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Setters and Accessors
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) setShortName:(NSString*)name	{ shortName = name; }

- (void) addChild:(SidebarNode*)node								{ if (!children) children = [[NSMutableArray alloc]init];  [children addObject:node];					[node setParent:self]; }
- (void) insertChild:(SidebarNode*)node atIndex:(NSUInteger)index	{ if (!children) children = [[NSMutableArray alloc]init];  [children insertObject:node atIndex:index];	[node setParent:self]; }
- (void) removeChild:(SidebarNode*)node				{ [children removeObject:node]; }
- (NSInteger) indexOfChildNode:(SidebarNode*)node	{ return [children indexOfObject:node]; }
- (SidebarNode*) childNodeAtIndex:(int)index		{ return [children objectAtIndex:index]; }
- (NSUInteger) numberOfChildren						{ return [children count]; }

- (BOOL) isExistentLocalRepositoryRef				{ return [self isLocalRepositoryRef] && pathIsExistentDirectory(path); }
- (BOOL) isLocalRepositoryRef						{ return (nodeKind == kSidebarNodeKindLocalRepositoryRef); }
- (BOOL) isServerRepositoryRef						{ return (nodeKind == kSidebarNodeKindServerRepositoryRef); }
- (BOOL) isSectionNode								{ return (nodeKind == kSidebarNodeKindSection); }
- (BOOL) isDraggable								{ return ![self isSectionNode]; }
- (BOOL) isRepositoryRef							{ return [self isLocalRepositoryRef] || [self isServerRepositoryRef]; }

- (NSAttributedString*) attributedStringForNode
{
	NSDictionary* attributesToApply;
	[self isServerRepositoryRef] ? italicSidebarFontAttributes : standardSidebarFontAttributes;
	if (![self isVirginRepository])
		attributesToApply = [self isServerRepositoryRef] ? italicSidebarFontAttributes : standardSidebarFontAttributes;
	else
		attributesToApply = [self isServerRepositoryRef] ? italicVirginSidebarFontAttributes : standardVirginSidebarFontAttributes;
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
	[part appendFormat:@"<%@{ caption = %@, path = %@ }\n", [self className], shortName, path];
	for (SidebarNode* node in children)
		[part appendString:[node description]];
	if (recentConnections)
		for (SidebarNode* node in recentConnections)
		{
			for (NSInteger i = 0; i < depth+1; i++)
				[part appendString:@"   "];
			[part appendFormat:@"recentConnection: %@ @ %@\n", [node shortName], [node path]];
		}
	
	return part;
}


// Duplicate a tree but don't copy the immutable bits, so the size of the copy is smallish.
- (SidebarNode*) copyNodeTree
{
	SidebarNode* newNode = [[SidebarNode alloc]init];
	newNode->nodeKind    = nodeKind;
	newNode->shortName	 = shortName;
	newNode->path		 = path;
	newNode->icon        = icon;
	newNode->isExpanded	 = isExpanded;
	newNode->hasPassword = hasPassword;

	if (children)
	{
		newNode->children = [[NSMutableArray alloc]init];
		for (SidebarNode* node in children)
			[newNode->children addObject:[node copyNodeTree]];
		for (SidebarNode* node in newNode->children)
			[node setParent:newNode];
	}
	if (recentConnections)
		newNode->recentConnections = [NSMutableArray arrayWithArray:recentConnections];

	return newNode;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Decorated Paths
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) fullURLPath
{
	if (!hasPassword || ![self isServerRepositoryRef])
		return path;	
	return FullServerURL(path, YES);
}

- (NSString*) pathHidingAnyPassword
{
	if (![self isServerRepositoryRef])
		return path;

	NSString* pass = [[NSURL URLWithString:path] password];
	if (!pass)
		return path;

	NSMutableString* newString = [NSMutableString stringWithString:path];
	[newString replaceOccurrencesOfString:pass withString:@"***" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
	return newString;
}




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Saving & Loading
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) encodeWithCoder:(NSCoder*)coder
{
	// We don't include the icon here since it takes up a lot of room. Eg a document with only 8 repositories has a size of 768K
	// if the icons are included and 8K if the are omitted, so we leave the icons out and just reload them. Of course if the
	// files are no longer there then the icon will be different than the original icon.
	
	[coder encodeInt:nodeKind forKey:@"nodeType"];
	[coder encodeObject:children forKey:@"children"];
	[coder encodeObject:shortName forKey:@"caption"];
	[coder encodeBool:isExpanded forKey:@"nodeIsExpanded"];
	[coder encodeBool:hasPassword forKey:@"nodeHasPassword"];
	[coder encodeObject:path forKey:@"path"];
	[coder encodeObject:recentConnections forKey:@"recentConnections"];

	NSString* repositoryIdentity = [[AppController sharedAppController] repositoryIdentityForPath:path];
	if (repositoryIdentity)
		[coder encodeObject:repositoryIdentity forKey:@"repositoryIdentity"];
}


- (id) initWithCoder:(NSCoder*)coder
{
	[super init];
	nodeKind	= [coder decodeIntForKey:@"nodeType"];
	children	= [coder decodeObjectForKey:@"children"];
	shortName	= [coder decodeObjectForKey:@"caption"];
	isExpanded	= [coder decodeBoolForKey:@"nodeIsExpanded"];
	hasPassword	= [coder decodeBoolForKey:@"nodeHasPassword"];
	path		= [coder decodeObjectForKey:@"path"];
	recentConnections  = [coder decodeObjectForKey:@"recentConnections"];
	
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

	if ([self isServerRepositoryRef] && path)
	{
		if (hasPassword)
			[[[AppController sharedAppController] urlUsesPassword] addObject:path];
		else
			[[[AppController sharedAppController] urlUsesPassword] removeObject:path];		
	}
	
	if ([self isRepositoryRef] && path)
	{
		NSString* repositoryIdentity = [coder decodeObjectForKey:@"repositoryIdentity"];
		if (repositoryIdentity)
			[[AppController sharedAppController]  setRepositoryIdentity:repositoryIdentity  ForPath:path];
		[[AppController sharedAppController] computeRepositoryIdentityForPath:path];
	}

	// Regenerate the icon as above to save space.
	[self refreshNodeIcon];

	return self;
}

- (void) refreshNodeIcon
{
	if (nodeKind == kSidebarNodeKindLocalRepositoryRef)
		icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
	else if (nodeKind == kSidebarNodeKindServerRepositoryRef)
		icon = [NSImage imageNamed:NSImageNameNetwork];	
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Root Changeset
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) addRecentConnection:(SidebarNode*)mark
{
	if (!recentConnections)
		recentConnections = [[NSMutableArray alloc]init];
	
	[recentConnections removeObject:mark];		// Remove old occurrences of equivalent records.
	[recentConnections insertObject:mark atIndex:0];
}

// Virgin repositories are freshly initialized repositories in mercurial without any commits in them at all. The first commit or
// push to such a repository will "crystalize" the repository in this new state.
- (BOOL) isVirginRepository
{
	static NSString* virginRepository = @"000000000000";
	NSString* repositoryIdentity  = [self repositoryIdentity];
	return [virginRepository isEqualToString:repositoryIdentity];
}

- (BOOL) isCompatibleTo:(SidebarNode*)other
{
	NSString* repositoryIdentitySelf  = [self repositoryIdentity];
	NSString* repositoryIdentityOther = [other repositoryIdentity];

	if (repositoryIdentitySelf == nil || repositoryIdentityOther == nil)
		return NO;
	if ([self isVirginRepository] || [other isVirginRepository])
		return YES;
	return [repositoryIdentitySelf isEqualToString:repositoryIdentityOther];
}

- (NSString*) repositoryIdentity	{ return [[AppController sharedAppController] repositoryIdentityForPath:path]; }

- (void) pruneRecentConnectionsOf:(NSString*)deadPath
{
	if ([self isRepositoryRef])
	{
		NSMutableArray* nodes = [self recentConnections];
		NSMutableArray* newNodes = [NSMutableArray arrayWithArray:nodes];		
		for (SidebarNode* node in nodes)
			if ([[node path] containsString:deadPath])
				[newNodes removeObject:node];
		[self setRecentConnections:newNodes];
	}

	for (SidebarNode* child in [self children])
		[child pruneRecentConnectionsOf:deadPath];
}


@end
