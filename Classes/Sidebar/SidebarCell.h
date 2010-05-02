//
//  TSBadgeCell.h
//  Tahsis
//
//  Original version created by Matteo Bertozzi on 3/8/09.
//  Copyright 2009 Matteo Bertozzi. All rights reserved.
//  Extensive modifications made by Jason Harris 29/11/09.
//  Copyright 2009 Jason Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface SidebarCell : NSTextFieldCell
{
	@private
	NSString*	badgeString_;
	BOOL		hasBadge_;
	NSImage*	icon_;
}

@property (readwrite,assign) NSString* badgeString;
@property (readwrite,assign) BOOL hasBadge;
@property (readonly) NSImage* icon;

- (void) setIcon:(NSImage*)icon;

@end
