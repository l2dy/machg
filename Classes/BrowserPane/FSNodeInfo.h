//
//  FSNodeInfo.h
//
//  Copyright (c) 2001-2007, Apple Inc. All rights reserved.
//
//  Extensively modified by Jason Harris.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//
//  FSNodeInfo encapsulates information about a file or directory.
//  This implementation is not necessarily the best way to do something like this,
//  it is simply a wrapper to make the rest of the browser code easy to follow.

#import <Cocoa/Cocoa.h>
#import "Common.h"

#define notYetComputedIconCount		0	// we use 0 as the number to tell us we still haven't computed this value. (We compute the
										// value lazily when we need to.)


@interface FSNodeInfo : NSObject
{
  @private
	FSBrowser*	parentBrowser;				// The parent browser which this node belongs to
	NSString*   relativePath;				// Path component relative to the parent.
	NSString*   absolutePath;
	NSMutableDictionary* childNodes;		// map of pathComponent -> childNode
	NSArray*	sortedChildNodeKeys;		// sorted array of all the keys of childNodes
	BOOL		haveComputedTheProperties;	// The final step of updating the properties of a node is to compute the properties of the
											// node from its children. This is also used as a "dirty" flag when doing incremental
											// merges of new changes into an existing tree.

	HGStatus	hgStatus;					// The status of the node.
	NSInteger	maxIconCountOfSubitems_;	// The maximum number of icons decorating the files and directories within this
											// directory. (we need to leave space when drawing for this.) (This is not the icon
											// count of this directory but the maximum of the icon counts each of the things in
											// this directory.)
}

@property (readwrite,assign) FSBrowser* parentBrowser;
@property (readonly, assign) NSString* relativePath;
@property (readwrite,assign) NSString* absolutePath;
@property (readwrite,assign) NSMutableDictionary* childNodes;
@property (readwrite,assign) NSArray* sortedChildNodeKeys;
@property (readwrite,assign) BOOL haveComputedTheProperties;
@property (readwrite,assign) HGStatus hgStatus;


+ (HGStatus)	statusEnumFromLetter:(NSString*)statusLetter;

+ (FSNodeInfo*)	newEmptyTreeRootedAt:(NSString*)theAbsolutePath;
- (FSNodeInfo*)	fleshOutTreeWithStatusLines:(NSArray*)hgStatusLines withParentBrowser:(FSBrowser*)browser;	// add in new changes to the tree
- (FSNodeInfo*) shallowTreeCopyMarkingPathsDirty:(NSArray*)theAbsolutePaths;	// Do a shallow copy of the tree copying those bits down to the parts
																				// we are going to dirty. for the bits we are dirtying, do a deep copy
																				// and dirty them.
- (FSNodeInfo*) shallowTreeCopyRemoving:(NSArray*)theAbsolutePaths;				// Do a shallow copy of the tree except for the bits we are removing.
																				// For these bits create copies down to the level of the parts we are
																				// removing.


- (NSString*)	fsType;
- (NSString*)	absolutePath;
- (NSString*)	lastPathComponent;
- (BOOL)		isLink;
- (BOOL)		isDirectory;
- (BOOL)		isReadable;
- (BOOL)		isVisible;
- (BOOL)		isDirty;


- (NSImage*)	iconImageOfSize:(NSSize)size;		// this is the icon of the file (eg a xcode document icon, or xcode icon for a .h file, etc.)
- (NSArray*)	notableIconImages;


- (FSNodeInfo*) nodeForPathFromRoot:(NSString*)thePath;
- (int)			computeChangeCount;					// The number of modified, removed, and added files in the whole tree
- (int)			maxIconCountOfSubitems;

// Preview support
- (NSImage*)	iconImageForPreview;
- (NSAttributedString*) attributedInspectorStringForFSNode;

@end




