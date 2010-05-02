//
//  TitledButton.h
//  MacHg
//
//  Created by Jason Harris on 3/12/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HelpButton : NSButton
{
	NSString*			helpAnchorName_;
}
@property (readwrite, retain) NSString* helpAnchorName;

@end
