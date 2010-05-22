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
	LabelData* label_;
	LogEntry*  entry_;
}

@property (nonatomic, assign) LogEntry* entry;
@property (nonatomic, assign) LabelData* label;


// Initilization
- (id) initWithLabel:(LabelData*)label andLogEntry:(LogEntry*)entry;
+ (NSTextAttachment*) labelButtonAttachmentWithLabel:(LabelData*)label andLogEntry:(LogEntry*)entry;


// Set members
- (void) setButtonTitle:(NSString*)title;
- (void) setFileNameFromRelativeName:(NSString*)relativeName;


// Actions
- (IBAction) displayLabel:(id)sender;

@end
