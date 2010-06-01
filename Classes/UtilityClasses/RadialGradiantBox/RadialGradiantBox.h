//
//  RadialGradiantBox.h
//  MacHg
//
//  Created by Jason Harris on 6/1/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CIFilter;


// This box draws itself with a radial gradiant centered on the centering Object
@interface RadialGradiantBox : NSBox
{
	IBOutlet NSView*	centeringObject;
	NSArray*			foregroundFilters_;
	NSArray*			backgroundFilters_;
	NSPoint				offsetFromCenter_;
	CIVector*			lastCenterForGradiant_;
	NSNumber*			radius_;
}

- (void) setRadius:(NSNumber*)r;
- (void) setOffsetFromCenter:(NSPoint)offset;
@end
