#import <Cocoa/Cocoa.h>

/*
 *  DTCPathView � 2004 Daniel Todd Currie
 *  Line of Sight Software - http://los.dtcurrie.net
 *
 *  Requires Mac OS X v10.1.x
 *
 *  DTCPathView allows a Cocoa/Objective-C programmer to easily create
 *  an auto-completed absolute path string in a standard NSTextField.
 *
 *  IMPLEMENTATION:
 *
 *  You will need to create a DTCPathView instance using the init method,
 *  and use setFieldEditor so that pathView will behave as an NSControl:
 *
 *      pathView = [[DTCPathView alloc] init];
 *      [pathView setFieldEditor:YES];
 *
 *  DTCPathView will also need to be set as the field editor for the desired
 *  NSTextField(s).  This is done by placing the following method in the
 *  parent window's delegate (pathField is the text field that will
 *  adopt the path auto-completion behavior):
 *
 * - (id)windowWillReturnFieldEditor:(NSWindow*)sender toObject:(id)anObject
 *	 {
 *       return (anObject == pathField) ? pathView : nil;
 *   }
 *
 *
 *  The modifications here by Jason Harris removed some code and this code now only autocompletes directoires.
 *
 *  While pathField is first responder, any changes that are
 *  made to the pathField text must go through pathView.
 *  For example the following code should be used:
 *
 *      [pathView setString:newPath];
 *
 *  Instead of:
 *
 *      [pathField setStringValue:newPath];
 *
 *  The path search is case-insensitive, since the Finder is also case-
 *  insensitive.
 *
 *  Feel free to contact me at los@dtcurrie.net with any other
 *  comments/questions.
 */
// Modifications by Jason Harris, December 2009.

@interface DTCPathView : NSTextView
{
    NSFileManager* fileManager;
    BOOL manualSelection;
}

@end
