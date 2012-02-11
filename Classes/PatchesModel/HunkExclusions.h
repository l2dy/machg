//
//  HunkExclusions.h
//  MacHg
//
//  Created by Jason Harris on 1/21/12.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  HunkExclusions
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface HunkExclusions : NSObject
{
	NSMutableDictionary*		hunkExclusionsDictionary_;											// Storage for which hunks are being excluded from commits. Maps
																									// (NSString*)repoRoot-> (NSMutableDictionary*)filePaths ->
																									// (NSSet*)hunkHashes -> (NSString*)hunkHash 
	NSMutableDictionary*		validHunkHashDictionary_;											// Storage for all hunk hashes in a given file. Maps
																									// (NSString*)repoRoot-> (NSMutableDictionary*)filePaths ->
																									// (NSSet*)hunkHashes -> (NSString*)hunkHash 
	
}
- (HunkExclusions*) init;


// Accessors
- (NSDictionary*) repositoryHunkExclusionsForRoot:(NSString*)root;
- (NSDictionary*) repositoryValidHunkHashesForRoot:(NSString*)root;
- (NSSet*)		  hunkExclusionSetForRoot:(NSString*)root andFile:(NSString*)fileName;
- (NSSet*)		  validHunkHashSetForRoot:(NSString*)root andFile:(NSString*)fileName;


// Hunk handling
- (void)     disableHunk:(NSString*)hunkHash forRoot:(NSString*)root andFile:(NSString*)fileName;	// Add the hunk hash to the dictionary of exclusions for the given
																									// file in the given repository 
- (void)     enableHunk: (NSString*)hunkHash forRoot:(NSString*)root andFile:(NSString*)fileName;	// Remove the hunk hash from the dictionary of exclusions for the
																									// given file in the given repository 
- (void)	 excludeFile:(NSString*)fileName forRoot:(NSString*)root;								// exclude all hunk hashes of the given file in the given repository 
- (void)	 includeFile:(NSString*)fileName forRoot:(NSString*)root;								// include all hunk hashes of the given file in the given repository 

- (void)	 updateExclusionsForPatchData:(PatchData*)patchData andRoot:(NSString*)root;			// Given a current patch for the current repository update the
																									// exclusions (possibly eliminating some exclusions which no longer
																									// exist) 

// Finding paths with exclusions
- (NSArray*) absolutePathsWithExclusionsForRoot:(NSString*)root;									// Return all the absolute paths effected by the exclusions for the
																									// given repository root 
- (NSArray*) contestedPathsIn:(NSArray*)paths forRoot:(NSString*)root;								// Out of the given paths return those which are effected by the
																									// exclusions. (The intersection of all paths with exclusions and the
																									// given paths.) 
- (NSArray*) uncontestedPathsIn:(NSArray*)paths forRoot:(NSString*)root;							// Out of the given paths return those which are uneffected by the
																									// exclusions. (The given paths minus all paths with exclusions)
@end



// Dictionary keys
extern NSString* const kFileName;
extern NSString* const kRootPath;
extern NSString* const kHunkHash;