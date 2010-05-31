//
//  BackingPaneController.m
//  MacHg
//
//  Created by Jason Harris on 12/4/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "BackingPaneController.h"
#import <QuartzCore/CIFilter.h>


@implementation BackingPaneController

@synthesize buttonBox;
@synthesize backingBox;
@synthesize myDocument;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BackingPaneController*) initBackingPaneControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"BackingPane" owner:self];
	return self;
}

- (void) awakeFromNib
{
}


@end


@implementation RadialGradiantBox : NSBox
{
}

// If anyone knows how to implement this better please tell me...
- (void) drawRect:(NSRect)dirtyRect
{
	CIColor* black   = [CIColor colorWithRed:  0.0/255.0 green:  0.0/255.0 blue:  0.0/255.0 alpha:1.0];
	CIColor* color0  = [CIColor colorWithRed: 77.0/255.0 green: 78.0/255.0 blue: 87.0/255.0 alpha:0.8];
	CIColor* color1  = [CIColor colorWithRed: 39.0/255.0 green: 40.0/255.0 blue: 52.0/255.0 alpha:0.5];
	NSRect buttonBoxFrame = [centeringObject bounds];
	NSRect other = [centeringObject convertRect:buttonBoxFrame toView:self];
	CIVector* center = [CIVector vectorWithX:NSMidX(other) Y:NSMidY(other)];
	NSNumber* radius = [NSNumber numberWithFloat:450.0];
	
	CIFilter* gradiantFilter = [CIFilter filterWithName:@"CIGaussianGradient"];
	[gradiantFilter setValue:color0 forKey:@"inputColor0"];
	[gradiantFilter setValue:color1 forKey:@"inputColor1"];
	[gradiantFilter setValue:center forKey:@"inputCenter"];
	[gradiantFilter setValue:radius forKey:@"inputRadius"];

	
	CIFilter* constantFilter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
	[constantFilter setValue:black forKey:@"inputColor"];

	NSArray* gradiantAttributes   = [NSArray arrayWithObject:gradiantFilter];
	NSArray* backgroundAttributes = [NSArray arrayWithObject:constantFilter];
	[[self layer] setFilters: gradiantAttributes];
	[[self layer] setBackgroundFilters:backgroundAttributes];
}


@end
