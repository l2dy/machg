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

typedef enum
{
	eDiffFileAdded	 = 0,
	eDiffFileChanged = 1,
	eDiffFileRemoved = 2
} DiffButtonType;

@interface DiffTextButtonCell : TextButtonCell
{
	NSString* absoluteFileName_;
	LogEntry* backingLogEntry_;
	DiffButtonType type_;
}

@property (nonatomic, assign) DiffButtonType type;
@property (nonatomic, assign) NSString* absoluteFileName;
@property (nonatomic, assign) LogEntry* backingLogEntry;

// Initilization
- (id) initWithLogEntry:(LogEntry*)entry;

// Set members
- (void) setButtonTitle:(NSString*)title;
- (void) setFileNameFromRelativeName:(NSString*)relativeName;

// Actions
- (IBAction) displayDiff:(id)sender;

@end
