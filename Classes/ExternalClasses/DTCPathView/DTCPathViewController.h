#import <Cocoa/Cocoa.h>
#import "DTCPathView.h"

@interface DTCPathViewController : NSObject
{
    IBOutlet NSTextField* pathField;
    DTCPathView* pathView;
}

@end
