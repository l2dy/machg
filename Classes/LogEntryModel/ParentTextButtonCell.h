//
//  ParentRevisionTextButtonCell.h
//  MacHg
//
//  Created by Eugene Golushkov on 26.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LogEntry.h"
#import "TextButtonCell.h"


@interface ParentTextButtonCell : TextButtonCell
{
	LogEntry*  entry_;
}

@property (nonatomic, assign) LogEntry* entry;

- (id) initWithLogEntry:(LogEntry*)entry;
+ (NSTextAttachment*) parentButtonAttachmentWithText:(NSString*)label andLogEntry:(LogEntry*)entry;

@end
