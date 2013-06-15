//
//  SidebarCell.h
//  Tahsis
//
//  Original version created by Matteo Bertozzi on 3/8/09.
//  Copyright 2009 Matteo Bertozzi. All rights reserved.
//  Extensive modifications made by Jason Harris 29/11/09.
//  Copyright 2009 Jason Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface SidebarCell : NSTextFieldCell

@property NSString* badgeString;
@property BOOL hasBadge;
@property (readonly) NSImage* icon;
@property (weak) SidebarNode* node;

- (void) setIcon:(NSImage*)icon;

@end
