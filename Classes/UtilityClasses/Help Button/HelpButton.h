//
//  TitledButton.h
//  MacHg
//
//  Created by Jason Harris on 3/12/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>


@interface HelpButton : NSButton
{
	HelpButton* __weak	weakSelf;				// We need this as the target of the action since setTarget:self creates a retain cycle
}
@property NSString* helpAnchorName;

@end
