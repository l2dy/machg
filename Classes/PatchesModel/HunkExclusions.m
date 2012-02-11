//
//  HunkExclusions.m
//  MacHg
//
//  Created by Jason Harris on 01/22/12.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "Common.h"
#import "PatchData.h"
#import "HunkExclusions.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  HunkExclusions
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation HunkExclusions

// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

+ (HunkExclusions*) hunkExclusionsWithExclusions:(NSMutableDictionary*)exclusions
{
	return [[HunkExclusions alloc] initWithExclusions:exclusions];
}

- (HunkExclusions*) initWithExclusions:(NSMutableDictionary*)exclusions
{
	self = [super init];
    if (self)
		exclusionsDictionary_ = exclusions;
	return self;
}

- (HunkExclusions*) init
{
	self = [super init];
    if (self)
		exclusionsDictionary_ = [[NSMutableDictionary alloc]init];
	return self;	
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[coder encodeObject:exclusionsDictionary_ forKey:@"hunkExclusionsDictionary"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	exclusionsDictionary_ = [coder decodeObjectForKey:@"hunkExclusionsDictionary"];
	return self;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Including / Excluding Hunks
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) disableHunk:(NSString*)hunkHash forRoot:(NSString*)root andFile:(NSString*)fileName
{
	NSMutableDictionary* repositoryExclusions = [exclusionsDictionary_ objectForKey:root addingIfNil:[NSMutableDictionary class]];
	NSMutableSet* set = [repositoryExclusions objectForKey:fileName addingIfNil:[NSMutableSet class]];
	[set addObject:hunkHash];
}

- (void) enableHunk: (NSString*)hunkHash forRoot:(NSString*)root andFile:(NSString*)fileName
{
	NSMutableDictionary* repositoryExclusions = [exclusionsDictionary_ objectForKey:root];
	NSMutableSet* set = [repositoryExclusions objectForKey:fileName];
	[set removeObject:hunkHash];
	if (IsEmpty(set))
	{
		[repositoryExclusions removeObjectForKey:fileName];
		if (IsEmpty(repositoryExclusions))
			[exclusionsDictionary_ removeObjectForKey:root];
	}
}

- (NSDictionary*) repositoryExclusionsForRoot:(NSString*)root
{
	NSMutableDictionary* repositoryExclusions = [exclusionsDictionary_ objectForKey:root];
	return repositoryExclusions;
}

- (NSSet*) exclusionsForRoot:(NSString*)root andFile:(NSString*)fileName
{
	NSMutableDictionary* repositoryExclusions = [exclusionsDictionary_ objectForKey:root];
	NSMutableSet* set = [repositoryExclusions objectForKey:fileName];
	return set;
}

- (void) updateExclusionsForPatchData:(PatchData*)patchData andRoot:(NSString*)root
{
	NSMutableDictionary* repositoryExclusions = [exclusionsDictionary_ objectForKey:root];
	if (!repositoryExclusions)
		return;
	for (FilePatch* filePatch in [patchData filePatches])
		if (filePatch)
		{
			NSString* fileName = pathDifference(root,filePatch->filePath);
			NSMutableSet* currentSet = [repositoryExclusions objectForKey:fileName];
			if (!currentSet)
				continue;
			NSSet* validHunkHases = filePatch->hunkHashesSet;
			[currentSet intersectSet:validHunkHases];
			if (IsEmpty(currentSet))
			{
				[repositoryExclusions removeObjectForKey:fileName];
				if (IsEmpty(repositoryExclusions))
					[exclusionsDictionary_ removeObjectForKey:root];
			}
		}
}

- (NSString*) description
{
	return [exclusionsDictionary_ description];
}

@end
