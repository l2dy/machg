//
//  MySheetWindowController.h
//  MacHg
//
//  Created by Jason Harris on 3/13/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

// This sheet controller is the basis for all of our sheets. It catches the command key being pressed, cancel events, and
// initilization, etc.
@interface BaseSheetWindowController : NSWindowController
@end
