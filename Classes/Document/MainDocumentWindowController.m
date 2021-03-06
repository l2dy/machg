//
//  MyWindowController.m
//  MacHg
//
//  Created by Jason Harris on 1/31/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "MainDocumentWindowController.h"
#import "Common.h"
#import "MacHgDocument.h"
#import "Sidebar.h"
#import "SidebarNode.h"

@implementation MainDocumentWindowController

- (MainDocumentWindowController*) initWithWindowNibName:(NSString*)nibName owner:(id)owner
{
	self = [super initWithWindowNibName:nibName owner:owner];
	if (!self)
		return nil;
	[self observe:kSidebarSelectionDidChange from:nil byCalling:@selector(synchronizeWindowTitleWithDocumentName)];
	return self;
}

- (NSString*) windowTitleForDocumentDisplayName:(NSString*)displayName
{
	MacHgDocument* myDocument = DynamicCast(MacHgDocument,self.document);
	if (myDocument.localRepoIsSelectedAndReady)
		return fstr(@"%@ - %@", displayName, [myDocument.sidebar.selectedNode shortName]);
	return displayName;
}

- (void) dealloc	{ [self stopObserving]; }

@end
