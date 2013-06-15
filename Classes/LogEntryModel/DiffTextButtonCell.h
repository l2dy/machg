//
//  DiffTextButtonCell.h
//  MacHg
//
//  Created by Jason Harris on 5/22/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LogEntry.h"
#import "TextButtonCell.h"
#import "Common.h"

@interface DiffTextButtonCell : TextButtonCell

@property (nonatomic) NSString* absoluteFileName;
@property (nonatomic) LogEntry* backingLogEntry;
@property DiffButtonType type;

// Initilization
- (id) initWithLogEntry:(LogEntry*)entry;
+ (NSTextAttachment*) diffButtonAttachmentWithLogEntry:(LogEntry*)entry andFile:(NSString*)file andType:(DiffButtonType)t;

// Set members
- (void) setButtonTitle:(NSString*)title;
- (void) setFileNameFromRelativeName:(NSString*)relativeName;

// Actions
- (IBAction) displayDiff:(id)sender;

@end
