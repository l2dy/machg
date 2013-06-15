//
//  ParentRevisionTextButtonCell.h
//  MacHg
//
//  Created by Eugene Golushkov on 26.10.10.
//  Copyright 2010 Eugene Golushkov. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "LogEntry.h"
#import "TextButtonCell.h"


@interface ParentTextButtonCell : TextButtonCell

@property (nonatomic) LogEntry* entry;

- (id) initWithLogEntry:(LogEntry*)entry;
+ (NSTextAttachment*) parentButtonAttachmentWithText:(NSString*)label andLogEntry:(LogEntry*)entry;

@end
