#import "DTCPathViewController.h"

@implementation DTCPathViewController

- (void)awakeFromNib
{
    pathView = [[DTCPathView alloc] init];
    [pathView setFieldEditor:YES];
}

- (id)windowWillReturnFieldEditor:(NSWindow*)sender toObject:(id)anObject
{
	return (anObject == pathField) ? pathView : nil;
}

@end
