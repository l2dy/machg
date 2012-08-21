//
//  LabelTextButtonCell.h
//  MacHg
//
//  Created by Jason Harris on 5/22/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LogEntry.h"
#import "TextButtonCell.h"
#import "Common.h"

@interface LabelTextButtonCell : TextButtonCell
{
	LabelData* __strong label_;
	LogEntry*  __strong entry_;
}

@property (nonatomic, strong) LogEntry* entry;
@property (nonatomic, strong) LabelData* label;


// Initilization
- (id) initWithLabel:(LabelData*)label andLogEntry:(LogEntry*)entry;
+ (NSTextAttachment*) labelButtonAttachmentWithLabel:(LabelData*)label andLogEntry:(LogEntry*)entry;


// Set members
- (void) setButtonTitle:(NSString*)title;


// Actions
- (IBAction) gotoLabel:(id)sender;

@end
