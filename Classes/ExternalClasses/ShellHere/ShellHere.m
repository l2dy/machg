//
//  main.m
//  OpenTerminal
//
//  Created by John Daniel on 3/22/09.
//  Copyright Etresoft 2009. All rights reserved.
//  Basically just repackaged the code. It's almost all John's code but just wrapped a bit differently.
//  Copyright Jason F Harris, May 2010.
//

#import <Cocoa/Cocoa.h>
#import "Terminal.h"
#import "Finder.h"
#import <ScriptingBridge/ScriptingBridge.h>

// Calculate the quoted representation of a path.
NSString* quotePath(NSString* path);

id QuietApplicationWithBundleIdentifier(NSString* ident)
{
    int old_stderr = dup(STDERR_FILENO);
    close(STDERR_FILENO);
    int fd = open("/dev/null", O_WRONLY);
    dup2(fd, STDERR_FILENO);
    close(fd);
    id application = [SBApplication applicationWithBundleIdentifier: ident];
    close(STDERR_FILENO);
    dup2(old_stderr, STDERR_FILENO);
    close(old_stderr);
    return application;
}

// If this breaks in the future we can just go back to the way things where and use
//    DoTerminalScript([NSString stringWithFormat:@"cd '%@'", path]) sort of thing.
void OpenTerminalAt(NSString* path)
{	
	// Connect to the Terminal. It is running now...maybe with a blank
	// terminal window.
	TerminalApplication* terminal = QuietApplicationWithBundleIdentifier(@"com.apple.Terminal");
	
	// Find out if the Terminal is already running.
	bool terminalWasRunning = [terminal isRunning];
	
	// Get the Terminal windows.
	SBElementArray* terminalWindows = [terminal windows];
	
	TerminalTab* currentTab = nil;
	
	// If there is only a single window with a single tab, Terminal may
	// have been just launched. If so, I want to use the new window.
	if(!terminalWasRunning)
		for(TerminalWindow* terminalWindow in terminalWindows)
		{
			SBElementArray* windowTabs = [terminalWindow tabs];
			
			for(TerminalTab* tab in windowTabs)
				currentTab = tab;
		}
	
	// Create a "cd" command.
	NSString* command = [NSString stringWithFormat: @"cd %@", quotePath(path)];
	
	// Run the script.
	[terminal doScript:command in:currentTab];
	
	// Activate the Terminal. Hopefully, the new window is already open and
	// is will be brought to the front.
	[terminal activate];
}

void DoCommandsInTerminalAt(NSArray* cmds, NSString* path)
{	
	// Connect to the Terminal. It is running now...maybe with a blank
	// terminal window.
	TerminalApplication* terminal = QuietApplicationWithBundleIdentifier(@"com.apple.Terminal");
	
	// Find out if the Terminal is already running.
	bool terminalWasRunning = [terminal isRunning];
	
	// Get the Terminal windows.
	SBElementArray* terminalWindows = [terminal windows];
	
	TerminalTab* currentTab = nil;
	
	// If there is only a single window with a single tab, Terminal may
	// have been just launched. If so, I want to use the new window.
	if(!terminalWasRunning)
		for(TerminalWindow* terminalWindow in terminalWindows)
		{
			SBElementArray* windowTabs = [terminalWindow tabs];
			
			for(TerminalTab* tab in windowTabs)
				currentTab = tab;
		}
	
	// Create a "cd" command.
	NSString* cdCmd = [NSString stringWithFormat: @"cd %@", quotePath(path)];
	
	// get to the correct place.
	TerminalTab* newTab = [terminal doScript:cdCmd in:currentTab];
	
	// Do the actual command
	for (NSString* cmd in cmds)
		[terminal doScript:cmd in:newTab];

	// Activate the Terminal. Hopefully, the new window is already open and
	// is will be brought to the front.
	[terminal activate];
}

// Calculate the quoted representation of a path.
// AppleScript has a "quoted form of POSIX path" which isn't quite as
// good as the Finder's drag-n-drop conversion. Here, I will try to
// replicate what the Finder does to convert a Unicode path to something
// the Terminal can understand.
NSString* quotePath(NSString* path)
{
	// Oh god, not a scanner.
	NSScanner* scanner = [NSScanner scannerWithString: path];
	
	// I don't want to skip the default whitespace.
	[scanner setCharactersToBeSkipped: [NSCharacterSet illegalCharacterSet]];
	
	// Create a character set that will replace any unicode characters that
	// aren't path-friendly.
	NSMutableCharacterSet* punctuation =
    [NSMutableCharacterSet punctuationCharacterSet];
	
	// Add symbols and whitespace to the list to be replaced.
	[punctuation  formUnionWithCharacterSet: [NSCharacterSet symbolCharacterSet]];
	[punctuation  formUnionWithCharacterSet: [NSCharacterSet whitespaceCharacterSet]];
    
	// Important - remove the path delimiter. I don't want this replaced.
	[punctuation removeCharactersInString: @"/"];
	
	// Since I'm doing all the dirty work, I don't need double quotes around
	// the resulting string.
	NSMutableString* quotedPath = [NSMutableString new];
	
	// Create some strings for good and bad sets.
	NSString* good;
	NSString* bad;
	
	while(![scanner isAtEnd])
    {
		// Scan all the good characters I can find.
		if([scanner scanUpToCharactersFromSet: punctuation intoString: & good])
			[quotedPath appendString: good];
		
		// Scan all the bad characters that come next.
		if([scanner scanCharactersFromSet: punctuation intoString: & bad])
			
			// Now escape each bad character.
			for(NSInteger i = 0; i < [bad length]; ++i)
				[quotedPath appendFormat: @"\\%C", [bad characterAtIndex: i]];
    }
    
	return [quotedPath autorelease];
}