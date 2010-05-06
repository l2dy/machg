//
//  OptionController.h
//  MacHg
//
//  Created by Jason Harris on 1/20/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

// This class is a controller which is primarily hooked up in IB. It is designed to handle command line "options". Eg in mercurial
// we might have an option like "--rev 23", the the switchButton would be hooked to turn on/off the "--rev" bit, ie the
// optionIsSet. If there is a corresponding valueField then that would be hooked up to eg the "23" bit of the option.
//
// We programmatically hijack the action and target to point back to this object. When the user click on a button we
// programmatically do the right thing in our "option-handling" by showing/hiding the field if there is one, and then forwarding
// the action on to the original target. In this way the OptionController sits between the button & field which make up the
// option, and the original target of those buttons from Interface builder. (For now none of the buttons or fields hooked up to
// the controller actions / targets, but in the future maybe so we forward the original action to the original target anyway.)

@interface OptionController : NSObject
{
	IBOutlet NSButton*		optionSwitchButton;
	IBOutlet NSTextField*	optionValueField;
	NSString*				optionName;
	BOOL					specialHandling;
	id						originalTarget;		// We programmatically hijack the action and target of the button to point
	SEL						originalAction;
}
@property (readwrite,assign) BOOL	specialHandling;
@property (readwrite,assign) id		originalTarget;
@property (readwrite,assign) SEL	originalAction;


// Initialization
- (void)	  setName:(NSString*)name;

// Accessors
- (BOOL)      optionIsSet;
- (NSString*) optionValue;
+ (BOOL)	  containsOptionWhichIsSet:(NSArray*)options;

// Setters
- (void)	  setOverallState:(BOOL)state;
- (void)	  setOptionValue:(NSString*)value;
- (IBAction)  setOptionValueStateFromButton:(id)sender;

// Connections
- (void)	  addOptionToArgs:(NSMutableArray*)args;
- (void)	  setConnections:(NSMutableDictionary*)connections  fromOptionWithKey:(NSString*)key;
- (void)	  setOptionFromConnections:(NSMutableDictionary*)connections  forKey:(NSString*)key;
+ (void)	  setOptions:(NSArray*)options  fromConnections:(NSMutableDictionary*)connections  forKey:(NSString*)key;
+ (void)	  setConnections:(NSMutableDictionary*)connections  fromOptions:(NSArray*)options  forKey:(NSString*)key;

@end
