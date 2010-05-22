//
//  DiffTextButtonCell.h
//  MacHg
//
//  Created by Jason Harris on 5/22/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LogEntry.h"


@interface DiffTextButtonCell : NSObject
{
	NSString* absoluteFileName_;
	LogEntry* backingLogEntry_;
}

@property (nonatomic, assign) NSString* absoluteFileName;
@property (nonatomic, assign) LogEntry* backingLogEntry;

- (void) setFileNameFromRelativeName:(NSString*)relativeName;
- (IBAction) displayDiff:(id)sender;

@end
