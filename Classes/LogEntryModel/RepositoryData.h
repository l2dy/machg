//
//  RepositoryData.h
//  MacHg
//
//  Created by Jason Harris on 12/10/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

// A collection of Log entires.

#import <Cocoa/Cocoa.h>
@class MacHgDocument;
@class LogEntry;

@interface RepositoryData : NSObject <AccessesDocument>
{
	NSMutableDictionary*		revisionStringToLogEntry_; 	// Map of (NSString*)revision number -> (LogEntry*)entry. This map loads progressively as needed
	
	NSMutableDictionary*		parentsCollection_;			// Rev NSNumber -> parents  (NSMutableArray of NSNumber) this acts like a set but we need it ordered
	NSMutableDictionary*		childrenCollection_;		// Rev NSNumber -> children (NSMutableArray of NSNumber) this acts like a set but we need it ordered

	NSString*					rootPath_;					// The root of the repository
	LogEntry*					incompleteRevisionEntry_;	// This is the log entry for the incomplete revision (the next pending commit)
	BOOL						includeIncompleteRevision_;	// Do we include the incompleteRevision_ in the count of the total number of revisions. and in the LogTable's etc
	MacHgDocument*				myDocument;
	
	// Parent and tip info
	NSString*					parent_;					// parentRev:parentChangeset
	NSString*					parents_;					// parent1Rev:parent1Changeset (parent2Rev:parent2Changeset)
	NSString*					parentRevision_;			// parentRev
	NSString*					parent1Revision_;			// parent1Rev
	NSString*					parent2Revision_;			// parent2Rev
	NSString*					parentsRevisions_;			// parent1Rev (parent2Rev)
	NSString*					parentChangeset_;			// parentChangeset
	NSString*					parentsChangesets_;			// parent1Changeset (parent2Changeset)
	NSString*					tip_;						// tipRev:tipChangeset
	NSString*					tipRevision_;				// tipRev
	NSString*					tipChangeset_;				// tipChangeset
	NSString*					branchName_;				// name of the current branch we are on
	NSString*					heads_;						// space separated list of the form openHeadRev:openHeadChangeset 
	NSString*					headsChangesets_;			// space separated list of the form openHeadChangeset 
	NSString*					headsRevisions_;			// space separated list of the form openHeadRev 

	// Tags & Branches
	NSDictionary*				tagToLabelDictionary_;		// A dictionary mapping (NSString*)tag -> (LabelData*)label
	NSDictionary*				bookmarkToLabelDictionary_;	// A dictionary mapping (NSString*)bookmark -> (LabelData*)label
	NSDictionary*				branchToLabelDictionary_;	// A dictionary mapping (NSString*)branch -> (LabelData*)label
	NSDictionary*				openHeadToLabelDictionary_;	// A dictionary mapping (NSString*)rev(openHead) -> (LabelData*)label
	NSMutableDictionary*		revisionToLabels_;			// A dictionary mapping (NSString*)rev -> (NSArray*)of(LabelData*)labels	
	BOOL						updatingTags_;
	BOOL						updatingBranches_;
	BOOL						updatingBookmarks_;
	BOOL						updatingOpenHeads_;

	NSNumber*					inMergeState_;
	NSNumber*					hasMultipleOpenHeads_;
	NSString*					repositoryRevision_;
}

@property (readonly,assign) NSString*			 rootPath;
@property (readonly,assign) MacHgDocument*		 myDocument;
@property (readonly,assign) NSMutableDictionary* parentsCollection;
@property (readonly,assign) NSMutableDictionary* childrenCollection;
@property (readonly,assign) BOOL				 includeIncompleteRevision;


// Version Information
- (NSString*)	getHGParent;				// Gives the parent parentRev:parentChangeset string (if there are two it gives the first)
- (NSString*)	getHGParents;				// Gives the parents parentRev:parentChangeset (if there are two they are space separated)
- (NSString*)	getHGParent1Revision;		// Gives the parent revision (if there are two it gives the first)
- (NSString*)	getHGParent2Revision;		// Gives the second parent revision (if there is only one return null)
- (NSString*)	getHGParentsRevisions;		// Gives the parent revisions (if there are two they are space separated)
- (NSString*)	getHGParentsChangeset;		// Gives the parent changeset (if there are two it gives the first)
- (NSString*)	getHGParentsChangesets;		// Gives the parent changesets (if there are two they are space separated)
- (NSString*)	getHGTip;					// Gives the tip tipRev:tipChangeset
- (NSString*)	getHGTipRevision;			// Gives the tipRev
- (NSString*)	getHGTipChangeset;			// Gives the tipChangeset
- (NSString*)	getHGBranchName;			// Gives the name of the current branch we are on
- (NSString*)	getHGHeads;					// Gives the list of space separated openHeadRev:openHeadChangeset
- (NSString*)	getHGHeadsChangesets;		// Gives the list of space separated openHeadChangeset
- (NSString*)	getHGHeadsRevisions;		// Gives the list of space separated openHeadRev

- (NSDictionary*) tagToLabelDictionary;
- (NSDictionary*) bookmarkToLabelDictionary;
- (NSDictionary*) branchToLabelDictionary;
- (NSDictionary*) openHeadToLabelDictionary;
- (NSDictionary*) revisionToLabels;
- (BOOL)		  labelsAreFullyLoaded;

- (NSInteger)	computeNumberOfRevisions;
- (NSInteger)	computeNumberOfRealRevisions;

- (BOOL)		isCurrentRevisionTip;
- (BOOL)		revisionIsParent:(NSString*)rev;
- (BOOL)		inMergeState;				// Are we in the process of merging two branches? ie does 'hg parents --template "{rev} "'
											// return "num" or "num num" if the later then we are in a merge state.
- (BOOL)		hasMultipleOpenHeads;		// Do we have more than one "open" head in the repository. If not then we have nothing
											// to merge with.
- (NSString*)	incompleteRevision;

- (id)			initWithRootPath:(NSString*)rootPath andDocument:(MacHgDocument*)doc;
- (BOOL)		entryIsLoadedForRevisionNumber:(NSNumber*)rev;
- (LogEntry*)	rawEntryForRevisionString:(NSString*)revisionStr;	// Give the entry directly from the dictionary. Do no auto-loading or anything else
- (LogEntry*)	entryForRevisionString:(NSString*)revisionStr;		// This starts the loading process for the entry and surrounding entries if the entry is not fully loaded

- (NSArray*)	parentsOfRev:(NSNumber*)rev;
- (NSArray*)	childrenOfRev:(NSNumber*)rev;
- (NSSet*)		descendantsOfRev:(NSNumber*)rev;

- (void)		adjustCollectionForIncompleteRevisionAllowingNotification:(BOOL)allow;
- (void)		fillTableFrom:(NSInteger)lowLimit to:(NSInteger)highLimit;
- (void)		fleshOutParentsAndChildren:(LogEntry*)entry addRelationShips:(BOOL)add;
- (void)		setEntry:(LogEntry*)entry;

@end
