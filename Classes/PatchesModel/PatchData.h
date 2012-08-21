//
//  PatchData.h
//  MacHg
//
//  Created by Jason Harris on 4/23/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>


// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  HunkObject
// ------------------------------------------------------------------------------------

@interface HunkObject : NSObject
{
	FilePatch*  parentFilePatch;
	NSString*   hunkHeader;
	NSArray*    hunkBodyLines;
	NSString*   __strong hunkHash;
	NSInteger	changeLineCount;	// The number of changed lines in the hunk
	BOOL		binaryHunk;			// Is this hunk binary data
}
@property (readonly,strong) NSString* hunkHash;

+ (HunkObject*) hunkObjectWithLines:(NSMutableArray*)lines andParentFilePatch:(FilePatch*)parentFilePatch;
- (NSString*)   htmlizedHunk:(BOOL)sublineDiffing;	// The hunk header and hunk body together, but with html insertions for hilighting the diff 
- (NSString*)   hunkString;							// The hunk header and hunk body together
@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  FilePatch
// ------------------------------------------------------------------------------------

@interface FilePatch : NSObject
{
	NSString* __strong filePath;				// The repository relative path which this patch applies to
	NSString* __strong filePatchHeader;
	NSMutableArray* hunks;			// An array of HunkObjects
	NSMutableSet* hunkHashesSet;	// An array of the hases in the hunk Objects
	BOOL binaryPatch;				// Records wether this file patch is a binary one
}
@property (readonly,strong) NSString* filePath;
@property (readonly,strong) NSString* filePatchHeader;
@property (readonly) NSMutableArray* hunks;
@property (readonly) NSMutableSet* hunkHashesSet;
@property (readonly,assign) BOOL binaryPatch;

+ (FilePatch*) filePatchWithPath:(NSString*)path andHeader:(NSString*)header binary:(BOOL)binary;
- (void)	   addHunkObjectWithLines:(NSMutableArray*)lines;

- (NSString*)  filePatchExcluding:(NSSet*)excludedHunks;	// The header and body but with the exculded hunks filtered out
- (NSString*)  filePatchSelecting:(NSSet*)includedHunks;	// The header and body but with only the included hunks being included
- (NSString*)  htmlizedFilePatch:(BOOL)sublineDiffing;		// The header and body, but with html insertions for highlighting the diff
- (NSString*)  filePatchString;								// The header and body together

@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  PatchData
// ------------------------------------------------------------------------------------

@interface PatchData : NSObject
{
	// Note don't be confused between these file paths (of the source code being patched) and
	// the path to the actual patch	
	
	NSMutableDictionary* filePatchForFilePathDictionary_;	// Map of (NSString*)sourceCodeFilePath -> (FilePatch*)patch (mirrors filePatches_)
	NSMutableArray* filePatches_;							// Array of (FilePatch*)patch (mirrors filePatchForFilePath_)
	NSString*		__strong patchBody_;
	NSString*		cachedPatchBodyHTMLized_;
}	
@property (readonly,strong) NSString* patchBody;
@property (readonly) NSMutableArray* filePatches;

+ (PatchData*) patchDataFromDiffContents:(NSString*)diff;

- (FilePatch*) filePatchForFilePath:(NSString*)filePath;

- (NSAttributedString*) patchBodyColorized;

- (NSString*) patchBodyHTMLized;
- (NSString*) patchBodyString;

- (BOOL)      willExcludeHunksFor:(HunkExclusions*)hunkExclusions withRoot:(NSString*)root;				// Return YES if any of the hunks in any of the file patches are excluded
- (NSString*) patchBodyExcluding:(HunkExclusions*)hunkExclusions withRoot:(NSString*)root;				// Return the patch body filtering out the given exclusions
- (NSString*) patchBodySelecting:(HunkExclusions*)hunkExclusions withRoot:(NSString*)root;				// Return the patch body selecting only the given exclusions
- (NSString*) tempFileWithPatchBodyExcluding:(HunkExclusions*)hunkExclusions withRoot:(NSString*)root;	// Create a temporary file of the patch excluding the given exclusions 
- (NSString*) tempFileWithPatchBodySelecting:(HunkExclusions*)hunkExclusions withRoot:(NSString*)root;	// Create a temporary file of the patch selecting only the given exclusions 
- (NSArray*)  pathsAffectedByExclusions:(HunkExclusions*)hunkExclusions withRoot:(NSString*)root;		// The paths of the file patches which are affected by the exclusions

@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  PatchRecord
// ------------------------------------------------------------------------------------

@interface PatchRecord : NSObject
{
	NSString* __strong path_;		// This is the path to the patch file (and not anything to do with the paths in the patch.)
	NSString* author_;
	NSString* date_;
	NSString* commitMessage_;
	NSString* parent_;
	NSString* __strong nodeID_;
	PatchData* __strong patchData_;
	
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

@property (readonly,strong) NSString*	path;
@property (readonly,strong) NSString*	nodeID;
@property (readonly,strong) PatchData*	patchData;
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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Patch Utilities
// ------------------------------------------------------------------------------------

// Return the enum as a string for use via webview calls.
NSString* stringOfDifferencesWebviewDiffStyle();

