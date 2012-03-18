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
	NSMutableDictionary*		revisionNumberToLogEntry_;	// Map of (NSNumber*)revision number -> (LogEntry*)entry. This map
															// loads progressively as needed
	NSMutableDictionary*		oldRevisionNumberToLogEntry_;// Map of (NSNumber*)revision number -> (LogEntry*)entry. These are
															// the old or stale entries.

	NSString*					rootPath_;					// The root of the repository
	LogEntry*					incompleteRevisionEntry_;	// This is the log entry for the incomplete revision (the next pending commit)
	BOOL						includeIncompleteRevision_;	// Do we include the incompleteRevision_ in the count of the total number of revisions. and in the LogTable's etc
	MacHgDocument*				myDocument;
	
	LogGraph*					logGraph_;					// All the current line segments
	LogGraph*					oldLogGraph_;				// All the old line segments

	NSString*					hgIgnoreFilesRegEx_;		// This regular expression represents the combined regular expression
															// representing all of the .hgignore files on the path.
	NSDate*						hgIgnoreFilesTimeStamp_;	// This is the timestamp when we determined hgIgnoreFilesRegEx_
	
	NSInteger					badRepositoryReadCount_;	// Records the number of times we have tried to read in the repository
															// and failed
	BOOL						discarded_;					// When we abadon a repoository data it means the controlling document
															// has moved on to other repositories. None of our results or
															// computations for this repository data will be used
	
	// Parent and tip info from my combinedinfo extension
	NSNumber*					parent1Revision_;			// parent1Rev
	NSNumber*					parent2Revision_;			// parent2Rev
	NSString*					parent1Changeset_;			// parent1Changeset
	NSString*					parent2Changeset_;			// parent2Changeset
	NSNumber*					tipRevision_;				// tipRev
	NSString*					tipChangeset_;				// tipChangeset
	NSString*					branchName_;				// name of the current branch we are on
	NSMutableDictionary*		revisionNumberToLabels_;	// A dictionary mapping (NSNumber*)rev -> (NSArray*)of(LabelData*)labels
	BOOL						hasMultipleOpenHeads_;
}

@property (readonly,assign) NSString*		rootPath;
@property (readonly,assign) MacHgDocument*  myDocument;
@property (readonly,assign) BOOL			includeIncompleteRevision;
@property (readonly,assign) LogGraph*		logGraph;
@property (readonly,assign) LogGraph*		oldLogGraph;


// Initialization
- (id)			initWithRootPath:(NSString*)rootPath andDocument:(MacHgDocument*)doc;
- (void)		markAsDiscarded;			// Mark this repository data as no longer being used / needed


// .hgignore handling
- (NSString*)	combinedHGIgnoreRegEx;


// Version Information
- (NSNumber*)	getHGParent1Revision;		// Gives the parent revision (if there are two it gives the first)
- (NSNumber*)	getHGParent2Revision;		// Gives the second parent revision (if there is only one return null)
- (NSString*)	getHGParent1Changeset;		// Gives the parent changeset (if there are two it gives the first)
- (NSString*)	getHGParent2Changeset;		// Gives the second parent changesets (if there is only one return null)
- (NSNumber*)	getHGTipRevision;			// Gives the tipRev
- (NSString*)	getHGTipChangeset;			// Gives the tipChangeset
- (NSString*)	getHGBranchName;			// Gives the name of the current branch we are on
- (NSNumber*)	minimumParent;				// Gives the smallest parent


- (NSDictionary*) revisionNumberToLabels;
- (LogEntry*)	entryForRevision:(NSNumber*)revision;		// The entry for the given revision. This starts the loading process
															// for the entry and surrounding entries if the entry is not fully
															// loaded
- (NSInteger)	computeNumberOfRevisions;
- (NSInteger)	computeNumberOfRealRevisions;


// Derived Information
- (BOOL)		isCurrentRevisionTip;
- (BOOL)		revisionIsParent:(NSNumber*)rev;
- (BOOL)		inMergeState;					// Are we in the process of merging two branches? ie does 'hg parents --template "{rev} "'
												// return "num" or "num num" if the later then we are in a merge state.
- (BOOL)		hasMultipleOpenHeads;			// Do we have more than one "open" head in the repository. If not then we have nothing
												// to merge with.
- (BOOL)		isRollbackInformationAvailable;	// Could we rollback the last operation if we wanted to?
- (BOOL)	    isTipOfLocalBranch;				// Query the underlying repository to see if this version is the tip of the local branch.


// State Maintenance
- (BOOL)		rebaseInProgress;
- (void)		deleteRebaseState;
- (BOOL)		historyEditInProgress;
- (void)		deleteHistoryEditState;


- (NSNumber*)	incompleteRevision;
- (LogEntry*)	incompleteRevisionEntry;

- (NSSet*)		descendantsOfRevisionNumber:(NSNumber*)rev;
- (NSArray*)	parentsOfRevision:(NSNumber*)rev;
- (NSArray*)	childrenOfRevision:(NSNumber*)rev;

- (void)		adjustCollectionForIncompleteRevision;
- (void)		fillTableFrom:(NSInteger)lowLimit to:(NSInteger)highLimit;

@end
