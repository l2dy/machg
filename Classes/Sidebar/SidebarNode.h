//
//  SidebarNode.h
//  Sidebar
//
//  Original version created by Matteo Bertozzi on 3/8/09.
//  Copyright 2009 Matteo Bertozzi. All rights reserved.
//  Extensive modifications made by Jason Harris 29/11/09.
//  Copyright 2009 Jason Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

typedef enum
{
	eRepositoryIdentityIsGood	  = 0,
	eRepositoryIdentityIsDirty	  = 1,
	eRepositoryIdentityIsComputing = 2
} RepositoryIdentityStatus;



@interface SidebarNode : NSObject <NSCoding>
{
	SidebarNodeKind	nodeKind;
	NSMutableArray* children;			// If this is a group node then this contains the sidebar nodes below this one.
	SidebarNode*	parent;				// The parent sidebar node in the tree of nodes
	NSString*		shortName;			// This is a name used by you like myproject
	NSImage*		icon;				// An icon in the sidebar to represent this node
	BOOL			isExpanded;			// If this is a group node then this is the status of whether the group node is expanded
										// or not

	// If this node is a repository reference (local or server) then the following are relevant
	NSString*		path;				// The local file path or server path; ie something like  http://www.codebase.org/code/main/myproject
										// if it's a server or /Users/jason/Projects/MyProject if it's a local file path.
	NSMutableArray* recentConnections;	// Internal list of a number of other repository references from which this server has
										// pushed / pulled data.
}

@property (assign) SidebarNodeKind nodeKind;
@property (nonatomic, retain) NSMutableArray* children;
@property (assign, readwrite) BOOL isExpanded;
@property (assign, readwrite) SidebarNode* parent;
@property (assign, readonly)  NSString* shortName;
@property (readwrite, assign) NSString* path;
@property (readwrite, assign) NSMutableArray* recentConnections;

@property (assign) NSImage* icon;


// Constructors
+ (SidebarNode*) sectionNodeWithCaption:(NSString*)caption;
+ (SidebarNode*) nodeForLocalURL:(NSString*)path;
+ (SidebarNode*) nodeWithCaption:(NSString*)cap  forLocalPath:(NSString*)path;
+ (SidebarNode*) nodeWithCaption:(NSString*)cap  forServerPath:(NSString*)path;
+ (SidebarNode*) nodeWithCaption:(NSString*)cap  path:(NSString*)thePath  icon:(NSImage*)icn  nodeKind:(SidebarNodeKind)type;
- (SidebarNode*) copyNode;
- (SidebarNode*) copyNodeTree;


// Child maintenance
- (void) addChild:(SidebarNode*)node;
- (void) insertChild:(SidebarNode*)node atIndex:(NSUInteger)index;
- (void) removeChild:(SidebarNode*)node;
- (NSInteger) indexOfChildNode:(SidebarNode*)node;
- (SidebarNode*) childNodeAtIndex:(int)index;
- (NSUInteger) numberOfChildren;


// Setters
- (void) setNodeKind:(SidebarNodeKind)type;
- (void) setShortName:(NSString*)cap;


// Accessors
- (BOOL) isLocalRepositoryRef;
- (BOOL) isExistentLocalRepositoryRef;
- (BOOL) isServerRepositoryRef;
- (BOOL) isSectionNode;
- (BOOL) isDraggable;
- (BOOL) isRepositoryRef;
- (NSAttributedString*) attributedStringForNode;


// Decorated Paths
- (NSString*) fullURLPath;
- (NSString*) pathHidingAnyPassword;


// Saving and Loading
- (void) encodeWithCoder:(NSCoder*)coder;
- (id)   initWithCoder:(NSCoder*)coder;
- (void) refreshNodeIcon;


// Rootchangeset and Connections
- (NSString*) repositoryIdentity;
- (BOOL) isCompatibleToNodeInArray:(NSArray*)nodes;
- (BOOL) isCompatibleTo:(SidebarNode*)comp;
- (void) addRecentConnection:(SidebarNode*)mark;
- (void) pruneRecentConnectionsOf:(NSString*)deadPath;
- (BOOL) isVirginRepository;

@end
