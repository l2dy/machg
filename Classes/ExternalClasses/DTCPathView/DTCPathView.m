#import "DTCPathView.h"

@implementation DTCPathView

- (id)init
{
    fileManager = [NSFileManager defaultManager];
    return [super init];
}

//
// When the delete key is pressed and any part up to the end of the path is selected, there would be essentially no effect, as the
// auto-complete would just replace what was deleted. Therefore we must detect delete presses and alter the selection to obtain
// the desired behavior:
//
- (void)keyDown:(NSEvent*)theEvent
{
    if ([fileManager fileExistsAtPath:[[self string] stringByExpandingTildeInPath]] && [theEvent keyCode] == 51 && NSMaxRange([self selectedRange]) == [[self string] length] && manualSelection == NO)       // if string is valid path, delete key was pressed, and current selection goes to end of string, and current selection was not set manually by the user
    {
        NSRange selectionRange = NSMakeRange(([self selectedRange].location - 1), ([self selectedRange].length + 1));
        [self setSelectedRange:selectionRange];
    }
    
    [super keyDown:theEvent];
}


//
// Manual selections can also mess things up, as the user will expect the text that is manually selected to be removed and nothing
// more. However, the above method would cause the selected text plus the next character to the left to be deleted. Therefore we
// must detect when a manual selection is made and handle this special case accordingly:
//
- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity
{
    manualSelection = YES;
    
    return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
}

- (void)didChangeText
{
    if (manualSelection)     // if the text was selected manually, we don't want to auto-complete
    {
        manualSelection = NO;
        [super didChangeText];
        return;
    }
    
    if ([[self string] isEqualTo:@""])       // if there is no string, we won't bother trying to match it
    {
        [super didChangeText];
        return;
    }
    
    if ([fileManager fileExistsAtPath:[[self string] stringByExpandingTildeInPath]])     // if the current string is a valid path, we don't want to alter it
    {
        [super didChangeText];
        return;
    }
    
    NSArray* components = [[self string] pathComponents];
    NSArray* componentsBase;
    
    // get our search directory, described by componentsBase
    if ([components count] > 1)
        componentsBase = [components subarrayWithRange:NSMakeRange(0, [components count] - 1)];
    else
        componentsBase = components;
    
    NSArray* dirContents = [fileManager contentsOfDirectoryAtPath:[[NSString pathWithComponents:componentsBase] stringByExpandingTildeInPath] error:nil];
    
    // for each file in the search directory, we will check for any matches
    int i = 0;
    while (i < [dirContents count])
    {
        if ([[[dirContents objectAtIndex:i] lowercaseString] hasPrefix:[[components lastObject] lowercaseString]])
        {
            NSString* completedPath = [[NSString pathWithComponents:componentsBase] stringByAppendingPathComponent:[dirContents objectAtIndex:i]];
            
			// We should only complete directories
			BOOL isDir;
			[fileManager fileExistsAtPath:[completedPath stringByExpandingTildeInPath] isDirectory:&isDir];
			
			// don't auto-complete if path is not a dir
			if (!isDir)
				break;

            // calculate what part of the resulting path should be selected
            float incompleteLength = (float)[[self string] length];
            float selectionLength = (float)([completedPath length] - [[self string] length]);
            NSRange selectionRange = NSMakeRange(incompleteLength, selectionLength);
            
            // set our results
            [self setString:completedPath];
            [self setSelectedRange:selectionRange];
            
            [super didChangeText];
            return;
        }
        
        ++i;
    }
    
    [super didChangeText];
}

@end
