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

- (HunkExclusions*) init
{
	self = [super init];
    if (self)
	{
		hunkExclusionsDictionary_ = [[NSMutableDictionary alloc]init];
		validHunkHashDictionary_  = [[NSMutableDictionary alloc]init];
	}
	return self;	
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[coder encodeObject:hunkExclusionsDictionary_ forKey:@"hunkExclusionsDictionary"];
	[coder encodeObject:validHunkHashDictionary_  forKey:@"fileExclusionsDictionary"];
}

- (id) initWithCoder:(NSCoder*)coder
{
	hunkExclusionsDictionary_ = [coder decodeObjectForKey:@"hunkExclusionsDictionary"];
	validHunkHashDictionary_  = [coder decodeObjectForKey:@"fileExclusionsDictionary"];
	if (!hunkExclusionsDictionary_) hunkExclusionsDictionary_ = [[NSMutableDictionary alloc]init];
	if (!validHunkHashDictionary_)  validHunkHashDictionary_  = [[NSMutableDictionary alloc]init];
	return self;
}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Accessors
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSDictionary*) repositoryHunkExclusionsForRoot: (NSString*)root				{ return [hunkExclusionsDictionary_ objectForKey:root]; }
- (NSDictionary*) repositoryValidHunkHashesForRoot:(NSString*)root				{ return [validHunkHashDictionary_  objectForKey:root]; }
- (NSSet*) hunkExclusionSetForRoot:(NSString*)root andFile:(NSString*)fileName	{ return [[hunkExclusionsDictionary_ objectForKey:root] objectForKey:fileName]; }
- (NSSet*) validHunkHashSetForRoot:(NSString*)root andFile:(NSString*)fileName	{ return [[validHunkHashDictionary_  objectForKey:root] objectForKey:fileName]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Including / Excluding Hunks
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) disableHunk:(NSString*)hunkHash forRoot:(NSString*)root andFile:(NSString*)fileName
{
	NSMutableDictionary* repositoryHunkExclusions = [hunkExclusionsDictionary_ objectForKey:root addingIfNil:[NSMutableDictionary class]];
	NSMutableSet* set = [repositoryHunkExclusions objectForKey:fileName addingIfNil:[NSMutableSet class]];
	[set addObject:hunkHash];
}

- (void) enableHunk: (NSString*)hunkHash forRoot:(NSString*)root andFile:(NSString*)fileName
{
	NSMutableDictionary* repositoryHunkExclusions = [hunkExclusionsDictionary_ objectForKey:root];
	NSMutableSet* set = [repositoryHunkExclusions objectForKey:fileName];
	[set removeObject:hunkHash];
	if (IsEmpty(set))
	{
		[repositoryHunkExclusions removeObjectForKey:fileName];
		if (IsEmpty(repositoryHunkExclusions))
			[hunkExclusionsDictionary_ removeObjectForKey:root];
	}
}

- (void)	 excludeFile:(NSString*)fileName forRoot:(NSString*)root
{
	NSSet* validHunkHashSet = [self validHunkHashSetForRoot:root andFile:fileName];
	NSMutableDictionary* repositoryHunkExclusions = [hunkExclusionsDictionary_ objectForKey:root];
	[repositoryHunkExclusions setObject:[validHunkHashSet mutableCopy] forKey:fileName];
}

- (void)	 includeFile:(NSString*)fileName forRoot:(NSString*)root
{
	NSMutableDictionary* repositoryHunkExclusions = [hunkExclusionsDictionary_ objectForKey:root];
	[repositoryHunkExclusions removeObjectForKey:fileName];	
}


- (void) updateExclusionsForPatchData:(PatchData*)patchData andRoot:(NSString*)root
{
	NSMutableDictionary* repositoryValidHunkHashes = [validHunkHashDictionary_  objectForKey:root addingIfNil:[NSMutableDictionary class]];
	NSMutableDictionary* repositoryHunkExclusions  = [hunkExclusionsDictionary_ objectForKey:root];
	for (FilePatch* filePatch in [patchData filePatches])
		if (filePatch)
		{
			NSString* fileName = [filePatch filePath];
			NSSet* validHunkHases = [filePatch hunkHashesSet];
			[repositoryValidHunkHashes setObject:validHunkHases forKey:fileName];

			NSMutableSet* currentSet = [repositoryHunkExclusions objectForKey:fileName];
			if (!currentSet)
				continue;
			[currentSet intersectSet:validHunkHases];
			if (IsEmpty(currentSet))
			{
				[repositoryHunkExclusions removeObjectForKey:fileName];
				if (IsEmpty(repositoryHunkExclusions))
					[hunkExclusionsDictionary_ removeObjectForKey:root];
			}
		}
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Path accessors
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSArray*) absolutePathsWithExclusionsForRoot:(NSString*)root
{
	NSDictionary* repositoryHunkExclusions = [hunkExclusionsDictionary_ objectForKey:root];
	if (IsEmpty(repositoryHunkExclusions))
		return [NSArray array];
	NSMutableArray* paths = [[NSMutableArray alloc]init];
	for (NSString* key in [repositoryHunkExclusions allKeys])
		[paths addObject:fstr(@"%@/%@",root,key)];
	return paths;
}


- (NSArray*) contestedPathsIn:(NSArray*)paths forRoot:(NSString*)root
{
	NSArray* pathsWithExclusions = [self absolutePathsWithExclusionsForRoot:root];
	if (IsEmpty(pathsWithExclusions))
		return [NSArray array];
	
	NSMutableSet* setOfPaths = [NSMutableSet setWithArray:paths];
	[setOfPaths intersectSet:[NSSet setWithArray:pathsWithExclusions]];
	return [[setOfPaths allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (NSArray*) uncontestedPathsIn:(NSArray*)paths forRoot:(NSString*)root
{	
	NSArray* pathsWithExclusions = [self absolutePathsWithExclusionsForRoot:root];
	if (IsEmpty(pathsWithExclusions))
		return paths;
	
	NSMutableSet* setOfPaths = [NSMutableSet setWithArray:paths];
	[setOfPaths minusSet:[NSSet setWithArray:pathsWithExclusions]];
	return [[setOfPaths allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (NSString*) description
{
	return fstr(@"HunkExclusions:\n%@\nValidHunks:\n%@", [hunkExclusionsDictionary_ description], [validHunkHashDictionary_ description]);
}

@end
