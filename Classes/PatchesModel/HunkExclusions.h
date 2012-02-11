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
	NSMutableDictionary*		exclusionsDictionary_;	// Storage for which hunks are being excluded from commits. Maps
														// (NSString*)repoRoot-> (NSMutableDictionary*)filePaths ->
														//       (NSSet*)hunkHashes -> (NSString*)hunkHash	
}
+ (HunkExclusions*) hunkExclusionsWithExclusions:(NSMutableDictionary*)exclusions;
- (HunkExclusions*) initWithExclusions:(NSMutableDictionary*)exclusions;
- (HunkExclusions*) init;

- (void) disableHunk:(NSString*)hunkHash forRoot:(NSString*)root andFile:(NSString*)fileName;
- (void) enableHunk: (NSString*)hunkHash forRoot:(NSString*)root andFile:(NSString*)fileName;
- (NSSet*) exclusionsForRoot:(NSString*)root andFile:(NSString*)fileName;
- (NSDictionary*) repositoryExclusionsForRoot:(NSString*)root;
- (void) updateExclusionsForPatchData:(PatchData*)patchData andRoot:(NSString*)root;

@end
