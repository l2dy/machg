//
//  ScrollToForLogTable.h
//  MacHg
//
//  Created by Jason Harris on 3/12/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class LogTableView;

@interface ScrollToForLogTable : NSButton <NSMenuDelegate>
{
	IBOutlet LogTableView*	logTable;
	NSDictionary*			tagToLabelDictionary;
	NSDictionary*			bookmarkToLabelDictionary;
	NSDictionary*			branchToLabelDictionary;
	NSDictionary*			openHeadToLabelDictionary;
	NSMenu*					thePopUpMenu;
}

- (IBAction) scrollToLabel:(id)sender;

@end
