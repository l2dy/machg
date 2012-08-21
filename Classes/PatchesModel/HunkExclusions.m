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

NSString* const kFileName	= @"FileName";
NSString* const kRootPath	= @"RootPath";
NSString* const kHunkHash	= @"HunkHash";





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  HunkExclusions
// ------------------------------------------------------------------------------------
// MARK: -

@implementation HunkExclusions





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// ------------------------------------------------------------------------------------

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
	self = [super init];
    if (!self)
        return nil;

    hunkExclusionsDictionary_ = [coder decodeObjectForKey:@"hunkExclusionsDictionary"];
    validHunkHashDictionary_  = [coder decodeObjectForKey:@"fileExclusionsDictionary"];
    if (!hunkExclusionsDictionary_) hunkExclusionsDictionary_ = [[NSMutableDictionary alloc]init];
    if (!validHunkHashDictionary_)  validHunkHashDictionary_  = [[NSMutableDictionary alloc]init];
	return self;
}



// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Accessors
// ------------------------------------------------------------------------------------

- (NSDictionary*) repositoryHunkExclusionsForRoot: (NSString*)root				{ return hunkExclusionsDictionary_[root]; }
- (NSDictionary*) repositoryValidHunkHashesForRoot:(NSString*)root				{ return validHunkHashDictionary_[root]; }
- (NSSet*) hunkExclusionSetForRoot:(NSString*)root andFile:(NSString*)fileName	{ return hunkExclusionsDictionary_[root][fileName]; }
- (NSSet*) validHunkHashSetForRoot:(NSString*)root andFile:(NSString*)fileName	{ return validHunkHashDictionary_[root][fileName]; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Including / Excluding Hunks
// ------------------------------------------------------------------------------------

- (void) disableHunk:(NSString*)hunkHash forRoot:(NSString*)root andFile:(NSString*)fileName
{
	NSMutableDictionary* repositoryHunkExclusions = [hunkExclusionsDictionary_ objectForKey:root addingIfNil:[NSMutableDictionary class]];
	NSMutableSet* set = [repositoryHunkExclusions objectForKey:fileName addingIfNil:[NSMutableSet class]];
	[set addObject:hunkHash];
	NSDictionary* info = @{kFileName: nonNil(fileName), kRootPath: nonNil(root), kHunkHash: nonNil(hunkHash)};
	[self postNotificationWithName:kHunkWasExcluded userInfo:info];
}

- (void) enableHunk: (NSString*)hunkHash forRoot:(NSString*)root andFile:(NSString*)fileName
{
	NSMutableDictionary* repositoryHunkExclusions = hunkExclusionsDictionary_[root];
	NSMutableSet* set = repositoryHunkExclusions[fileName];
	[set removeObject:hunkHash];
	if (IsEmpty(set))
	{
		[repositoryHunkExclusions removeObjectForKey:fileName];
		if (IsEmpty(repositoryHunkExclusions))
			[hunkExclusionsDictionary_ removeObjectForKey:root];
	}
	NSDictionary* info = @{kFileName: nonNil(fileName), kRootPath: nonNil(root), kHunkHash: nonNil(hunkHash)};
	[self postNotificationWithName:kHunkWasIncluded userInfo:info];
}

- (void) excludeFile:(NSString*)fileName forRoot:(NSString*)root
{
	NSSet* validHunkHashSet = [self validHunkHashSetForRoot:root andFile:fileName];
	if (IsEmpty(validHunkHashSet)) return;
	NSMutableDictionary* repositoryHunkExclusions = [hunkExclusionsDictionary_ objectForKey:root addingIfNil:[NSMutableDictionary class]];
	repositoryHunkExclusions[fileName] = [validHunkHashSet mutableCopy];
	NSDictionary* info = @{kFileName: nonNil(fileName), kRootPath: nonNil(root)};
	[self postNotificationWithName:kFileWasExcluded userInfo:info];
}

- (void) includeFile:(NSString*)fileName forRoot:(NSString*)root
{
	NSMutableDictionary* repositoryHunkExclusions = hunkExclusionsDictionary_[root];
	[repositoryHunkExclusions removeObjectForKey:nonNil(fileName)];	
	NSDictionary* info = @{kFileName: nonNil(fileName), kRootPath: nonNil(root)};
	[self postNotificationWithName:kFileWasIncluded userInfo:info];
}


- (void) updateExclusionsForPatchData:(PatchData*)patchData andRoot:(NSString*)root within:(NSArray*)paths
{
	NSMutableDictionary* repositoryValidHunkHashes = [validHunkHashDictionary_  objectForKey:root addingIfNil:[NSMutableDictionary class]];
	NSMutableDictionary* repositoryHunkExclusions  = hunkExclusionsDictionary_[root];
	
	// For all file patches in the new patch data update them
	for (FilePatch* filePatch in [patchData filePatches])
		if (filePatch)
		{
			NSString* fileName = [filePatch filePath];
			NSSet* validHunkHases = [filePatch hunkHashesSet];
			repositoryValidHunkHashes[fileName] = validHunkHases;

			NSMutableSet* currentSet = repositoryHunkExclusions[fileName];
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
	
	// For all files registered to have exclusions, if the file no longer has modifications then remove the exclusions from the
	// dictionaries 
	NSArray* exclusionsRestricedToPaths = restrictPathsToPaths([self absolutePathsWithExclusionsForRoot:root], paths);
	for (NSString* path in exclusionsRestricedToPaths)
	{
		NSString* relativePath = pathDifference(root, path);
		if (![patchData filePatchForFilePath:relativePath])
		{
			[repositoryHunkExclusions  removeObjectForKey:relativePath];
			[repositoryValidHunkHashes removeObjectForKey:relativePath];
		}
	}
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Path accessors
// ------------------------------------------------------------------------------------

- (NSArray*) absolutePathsWithExclusionsForRoot:(NSString*)root
{
	NSDictionary* repositoryHunkExclusions = hunkExclusionsDictionary_[root];
	if (IsEmpty(repositoryHunkExclusions))
		return @[];
	NSMutableArray* paths = [[NSMutableArray alloc]init];
	for (NSString* key in [repositoryHunkExclusions allKeys])
		[paths addObject:fstr(@"%@/%@",root,key)];
	return paths;
}


- (NSArray*) contestedPathsIn:(NSArray*)paths forRoot:(NSString*)root
{
	NSArray* pathsWithExclusions = [self absolutePathsWithExclusionsForRoot:root];
	if (IsEmpty(pathsWithExclusions))
		return @[];
	
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
