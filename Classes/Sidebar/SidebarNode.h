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
	SidebarNode*	__strong parent;				// The parent sidebar node in the tree of nodes
	NSString*		__strong shortName;			// This is a name used by you like myproject
	NSImage*		__strong icon;				// An icon in the sidebar to represent this node
	BOOL			isExpanded;			// If this is a group node then this is the status of whether the group node is expanded
										// or not

	// If this node is a repository reference (local or server) then the following are relevant
	NSString*		__strong path;				// The local file path or server path; ie something like  http://www.codebase.org/code/main/myproject
										// if it's a server or /Users/jason/Projects/MyProject if it's a local file path.
	NSString*		__strong recentPushConnection;	// The path of the most recent push connection if there has been one.
	NSString*		__strong recentPullConnection;	// The path of the most recent pull connection if there has been one.
}

@property (assign) SidebarNodeKind nodeKind;
@property (nonatomic, strong) NSMutableArray* children;
@property (assign, readwrite) BOOL isExpanded;
@property (strong, readwrite) SidebarNode* parent;
@property (strong, readonly)  NSString* shortName;
@property (readwrite, strong) NSString* path;
@property (readwrite, strong) NSString* recentPushConnection;
@property (readwrite, strong) NSString* recentPullConnection;

@property (strong) NSImage* icon;


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
- (NSInteger) level;


// Setters
- (void) setNodeKind:(SidebarNodeKind)type;
- (void) setShortName:(NSString*)cap;


// Accessors
- (BOOL) isLocalRepositoryRef;
- (BOOL) isExistentLocalRepositoryRef;
- (BOOL) isMissingLocalRepositoryRef;
- (BOOL) isServerRepositoryRef;
- (BOOL) isSectionNode;
- (BOOL) isTopLevelSectionNode;
- (BOOL) isDraggable;
- (BOOL) isRepositoryRef;
- (NSArray*) allChildren;
- (NSAttributedString*) attributedStringForNodeAndSelected:(BOOL)selected;


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
- (SidebarNode*) copySubtreeCompatibleTo:(SidebarNode*)comp;
- (BOOL) isVirginRepository;

@end
