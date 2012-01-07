//
//  PatchData.h
//  MacHg
//
//  Created by Jason Harris on 4/23/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>

@interface FilePatch : NSObject
{
  @public
	NSString* filePath;
	NSString* filePatchHeader;
	NSMutableArray* hunks;
	NSMutableSet* hunkHashes;
}
- (void) finishHunk:(NSMutableArray*)lines;
- (NSString*) hashHunk:(NSString*)hunk;
- (NSString*) filterFilePatchWithExclusions:(NSSet*)excludedHunks;
@end





@interface PatchData : NSObject
{
	NSString* path_;
	NSString* author_;
	NSString* date_;
	NSString* commitMessage_;
	NSString* parent_;
	NSString* nodeID_;
	NSString* patchBody_;

	// Note don't be confused between these file paths (of the source code being patched) and
	// the path to the actual patch	

	NSMutableDictionary* excludedPatchHunksForFilePath_;	// Map of (NSString*)sourceCodeFilePath -> (NSMutableSet*)of(NSString*)excludedHunkNumber
	NSMutableDictionary* filePatchForFilePath_;				// Map of (NSString*)sourceCodeFilePath -> (FilePatch*)patch (mirrors filePatches_)
	NSMutableArray* filePatches_;							// Array of (FilePatch*)patch (mirrors filePatchForFilePath_)
	
	BOOL	  forceOption_;
	BOOL	  exactOption_;
	BOOL	  dontCommitOption_;
	BOOL	  importBranchOption_;
	BOOL	  guessRenames_;

	// If the PatchData is interactively modified keep track of which values have changed.
	BOOL	  authorIsModified_;
	BOOL	  dateIsModified_;
	BOOL	  commitMessageIsModified_;
	BOOL	  parentIsModified_;
}

@property (readwrite,assign) NSString*	path;
@property (readwrite,assign) NSString*	nodeID;
@property (readwrite,assign) NSString*	patchBody;
@property (readwrite,assign) NSMutableDictionary* excludedPatchHunksForFilePath;
@property BOOL forceOption;
@property BOOL exactOption;
@property BOOL dontCommitOption;
@property BOOL importBranchOption;
@property BOOL guessRenames;
@property BOOL authorIsModified;
@property BOOL dateIsModified;
@property BOOL commitMessageIsModified;
@property BOOL parentIsModified;

+ (PatchData*) patchDataFromFilePath:(NSString*)path;

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

- (BOOL) isModified;

- (NSAttributedString*) patchBodyColorized;

- (NSString*) patchBodyFiltered;

@end
