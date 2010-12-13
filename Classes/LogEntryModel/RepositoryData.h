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

	NSString*					rootPath_;					// The root of the repository
	LogEntry*					incompleteRevisionEntry_;	// This is the log entry for the incomplete revision (the next pending commit)
	BOOL						includeIncompleteRevision_;	// Do we include the incompleteRevision_ in the count of the total number of revisions. and in the LogTable's etc
	MacHgDocument*				myDocument;
	
	LogGraph*					logGraph_;
	
	// Parent and tip info
	NSNumber*					parent1Revision_;			// parent1Rev
	NSNumber*					parent2Revision_;			// parent2Rev
	NSString*					parent1Changeset_;			// parent1Changeset
	NSString*					parent2Changeset_;			// parent2Changeset
	NSNumber*					tipRevision_;				// tipRev
	NSString*					tipChangeset_;				// tipChangeset
	NSString*					branchName_;				// name of the current branch we are on
	NSMutableDictionary*		revisionNumberToLabels_;	// A dictionary mapping (NSNumber*)rev -> (NSArray*)of(LabelData*)labels	

	// Information Load Statues
	InformationLoadStatus		tipLoadStatus_;				// The status of the tip information in the repository
	InformationLoadStatus		parentsInfoLoadStatus_;		// The status of the information on the parents of the current
															// revision in the repository
	InformationLoadStatus		incompleteRevLoadStatus_;	// The status of the information on the incomplete revision
	InformationLoadStatus		labelsInfoLoadStatus_;		// The status of the labels information in the repository
	InformationLoadStatus		branchNameLoadStatus_;		// The status of the branch name information in the repository

	BOOL						hasMultipleOpenHeads_;
}

@property (readonly,assign) NSString*		rootPath;
@property (readonly,assign) MacHgDocument*  myDocument;
@property (readonly,assign) BOOL			includeIncompleteRevision;
@property (readonly,assign) LogGraph*		logGraph;

// Initilization
- (id)			initWithRootPath:(NSString*)rootPath andDocument:(MacHgDocument*)doc;


// Version Information
- (NSNumber*)	getHGParent1Revision;		// Gives the parent revision (if there are two it gives the first)
- (NSNumber*)	getHGParent2Revision;		// Gives the second parent revision (if there is only one return null)
- (NSString*)	getHGParent1Changeset;		// Gives the parent changeset (if there are two it gives the first)
- (NSString*)	getHGParent2Changeset;		// Gives the second parent changesets (if there is only one return null)
- (NSNumber*)	getHGTipRevision;			// Gives the tipRev
- (NSString*)	getHGTipChangeset;			// Gives the tipChangeset
- (NSString*)	getHGBranchName;			// Gives the name of the current branch we are on

- (NSDictionary*) revisionNumberToLabels;

- (NSInteger)	computeNumberOfRevisions;
- (NSInteger)	computeNumberOfRealRevisions;

- (BOOL)		isCurrentRevisionTip;
- (BOOL)		revisionIsParent:(NSNumber*)rev;
- (BOOL)		inMergeState;					// Are we in the process of merging two branches? ie does 'hg parents --template "{rev} "'
												// return "num" or "num num" if the later then we are in a merge state.
- (BOOL)		hasMultipleOpenHeads;			// Do we have more than one "open" head in the repository. If not then we have nothing
												// to merge with.
- (BOOL)		isRollbackInformationAvailable;	// Could we rollback the last operation if we wanted to?

- (NSNumber*)	incompleteRevision;
- (LogEntry*)	incompleteRevisionEntry;


- (LogEntry*)	entryForRevision:(NSNumber*)revision;		// This starts the loading process for the entry and surrounding entries if the entry is not fully loaded
- (void)		setEntriesAndNotify:(NSArray*)entries;		// Add the given entries to this repository and notify if anything changed

- (NSSet*)		descendantsOfRevisionNumber:(NSNumber*)rev;
- (NSArray*)	parentsOfRevision:(NSNumber*)rev;
- (NSArray*)	childrenOfRevision:(NSNumber*)rev;


- (void)		adjustCollectionForIncompleteRevisionAllowingNotification:(BOOL)allow;
- (void)		fillTableFrom:(NSInteger)lowLimit to:(NSInteger)highLimit;

@end
