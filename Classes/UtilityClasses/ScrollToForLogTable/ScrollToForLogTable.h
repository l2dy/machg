//
//  ScrollToForLogTable.h
//  MacHg
//
//  Created by Jason Harris on 3/12/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
@class LogTableView;

@interface ScrollToForLogTable : NSButton <NSMenuDelegate>
{
	IBOutlet LogTableView*	logTable;
	NSMenu*					thePopUpMenu;
}

- (IBAction) scrollToLabel:(id)sender;

@end
