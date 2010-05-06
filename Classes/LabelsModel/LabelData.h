//
//  LabelData.h
//  MacHg
//
//  Created by Jason Harris on 4/10/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>

typedef enum
{
	eNoLabelType	 = 0,
	eLocalTag		 = 1<<1,
	eGlobalTag		 = 1<<2,
	eBookmark		 = 1<<3,
	eActiveBranch	 = 1<<4,
	eInactiveBranch  = 1<<5,
	eClosedBranch	 = 1<<6,
	eOpenHead		 = 1<<7,
	eTagLabel		 = eGlobalTag | eLocalTag,
	eBranchLabel	 = eActiveBranch | eInactiveBranch | eClosedBranch,
	eBookmarkLabel   = eBookmark,
	eLocalLabel		 = eLocalTag | eBookmark,
	eStationaryLabel = eLocalTag | eGlobalTag,
	eNotOpenHead     = eTagLabel | eBranchLabel | eBookmarkLabel
} LabelType;


@interface LabelData : NSObject
{
	NSString* name_;
	NSString* revision_;
	NSString* changeset_;
	LabelType labelType_;
	NSString* info_;
}

@property (readonly,assign) NSString* name;
@property (readonly,assign) NSString* revision;
@property (readonly,assign) NSString* changeset;
@property (readonly,assign) LabelType labelType;
@property (readonly,assign) NSString* info;

// Initilization
+ (LabelData*) labelDataFromTagResultLine:(NSString*)line;
+ (LabelData*) labelDataFromBookmarkResultLine:(NSString*)line;
+ (LabelData*) labelDataFromBranchResultLine:(NSString*)line;
+ (LabelData*) labelDataFromOpenHeadsLine:(NSString*)line;


// Queries
- (BOOL) isTag;
- (BOOL) isBookmark;
- (BOOL) isBranch;
- (BOOL) isOpenHead;
- (BOOL) isLocal;
- (BOOL) isStationary;
- (BOOL) isEqualToLabel:(LabelData*)label;

- (NSString*) labelTypeDescription;
- (NSAttributedString*) labelTypeAttributedDescription;


// List Operations
+ (NSArray*) filterLabels:(NSArray*)labels byType:(LabelType)labelType;
+ (NSArray*) extractNameFromLabels:(NSArray*)labels;
+ (NSArray*) removeDuplicateLabels:(NSArray*)labels;

// Sorting
+ (NSArray*) descriptorsForSortByNameAscending;
+ (NSArray*) descriptorsForSortByRevisionAscending;
+ (NSArray*) descriptorsForSortByTypeAscending;



@end
