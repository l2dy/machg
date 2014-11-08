//
//  MacHgDocumentController.m
//  MacHg
//
//  Created by Jason Harris on 6/9/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import "MacHgDocumentController.h"


@implementation MacHgDocumentController

- (NSUInteger)maximumRecentDocumentCount
{
	NSUInteger recentCount = super.maximumRecentDocumentCount;
	return (recentCount > 0) ? recentCount : 1;
}

@end
