//
//  PatchData.h
//  MacHg
//
//  Created by Jason Harris on 4/23/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  FilePatch
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface FilePatch : NSObject
{
  @public
	NSString* filePath;
	NSString* filePatchHeader;
	NSMutableArray* hunks;
	NSMutableArray* hunkHashes;
	NSMutableSet* hunkHashesSet;
}
+ (FilePatch*) filePatchWithPath:(NSString*)path andHeader:(NSString*)header;
- (void) finishHunk:(NSMutableArray*)lines;
- (NSString*) filterFilePatchWithExclusions:(NSSet*)excludedHunks;
- (NSString*) htmlizedFilePatch;
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  PatchData
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface PatchData : NSObject
{
	// Note don't be confused between these file paths (of the source code being patched) and
	// the path to the actual patch	
	
	NSMutableDictionary* excludedPatchHunksForFilePath_;	// Map of (NSString*)sourceCodeFilePath -> (NSMutableSet*)of(NSString*)excludedHunkNumber
	NSMutableDictionary* filePatchForFilePath_;				// Map of (NSString*)sourceCodeFilePath -> (FilePatch*)patch (mirrors filePatches_)
	NSMutableArray* filePatches_;							// Array of (FilePatch*)patch (mirrors filePatchForFilePath_)
	NSString*		patchBody_;
}	
@property (readonly,assign) NSString* patchBody;
@property (readonly,assign) NSMutableArray* filePatches;
@property (readonly,assign) NSMutableDictionary* excludedPatchHunksForFilePath;

+ (PatchData*) patchDataFromDiffContents:(NSString*)diff;

- (NSAttributedString*) patchBodyColorized;

- (NSString*) patchBodyFiltered;
- (NSString*) patchBodyHTMLized;

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  PatchRecord
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface PatchRecord : NSObject
{
	NSString* path_;
	NSString* author_;
	NSString* date_;
	NSString* commitMessage_;
	NSString* parent_;
	NSString* nodeID_;
	PatchData* patchData_;
	
	BOOL	  forceOption_;
	BOOL	  exactOption_;
	BOOL	  dontCommitOption_;
	BOOL	  importBranchOption_;
	BOOL	  guessRenames_;

	// If the PatchRecord is interactively modified, then keep track of which values have changed.
	BOOL	  authorIsModified_;
	BOOL	  dateIsModified_;
	BOOL	  commitMessageIsModified_;
	BOOL	  parentIsModified_;
}

@property (readonly,assign) NSString*	path;
@property (readonly,assign) NSString*	nodeID;
@property (readonly,assign) PatchData*	patchData;
@property BOOL forceOption;
@property BOOL exactOption;
@property BOOL dontCommitOption;
@property BOOL importBranchOption;
@property BOOL guessRenames;
@property BOOL authorIsModified;
@property BOOL dateIsModified;
@property BOOL commitMessageIsModified;
@property BOOL parentIsModified;

+ (PatchRecord*) patchRecordFromFilePath:(NSString*)path;

- (BOOL) commitOption;
- (void) setCommitOption:(BOOL)value;

- (NSString*) author;
- (NSString*) date;
- (NSString*) commitMessage;
- (NSString*) parent;
- (void) setAuthor:(NSString*)author;
- (void) setDate:(NSString*)date;
- (void) setCommitMessage:(NSString*)message;
- (void) setParent:(NSString*)parent;
- (NSString*) patchName;
- (NSString*) patchBody;

- (BOOL) isModified;

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Patch Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------

// Return the enum as a string for use via webview calls.
NSString* stringOfDifferencesWebviewDiffStyle();

