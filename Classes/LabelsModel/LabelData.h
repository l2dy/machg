//
//  LabelData.h
//  MacHg
//
//  Created by Jason Harris on 4/10/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface LabelData : NSObject

@property (readonly) NSString* name;
@property (readonly) NSNumber* revision;
@property (readonly) NSString* changeset;
@property (readonly) LabelType labelType;

// Initilization
+ (LabelData*) labelWithName:(NSString*)n andType:(LabelType)t revision:(NSString*)r changeset:(NSString*)c;


// Queries
- (BOOL) isTag;
- (BOOL) isBookmark;
- (BOOL) isBranch;
- (BOOL) isOpenHead;
- (BOOL) isLocal;
- (BOOL) isStationary;
- (BOOL) isEqualToLabel:(LabelData*)label;

- (NSString*) revisionStr;
- (NSString*) labelTypeDescription;
- (NSAttributedString*) labelTypeAttributedDescription;


// List Operations
+ (NSArray*) filterLabels:(NSArray*)labels byType:(LabelType)type;
+ (NSArray*) extractNameFromLabels:(NSArray*)labels;
+ (NSArray*) removeDuplicateLabels:(NSArray*)labels;
+ (NSArray*) filterLabelsDictionary:(NSDictionary*)labelsDict byType:(LabelType)type;
+ (NSArray*) filterLabelsAndExtractNames:(NSArray*)labels byType:(LabelType)type;


// Sorting
+ (NSArray*) descriptorsForSortByNameAscending;
+ (NSArray*) descriptorsForSortByRevisionAscending;
+ (NSArray*) descriptorsForSortByTypeAscending;



@end
