//
//  MemUpController.m
//  MemUp
//
//  Created by Lukas on 25.11.13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "MemUpController.h"

@implementation MemUpController

- (UIView *)view
{
	if (_view == nil)
	{
		_view = [[UIView alloc] initWithFrame:CGRectMake(3, 0, 314, 71)];

		UIImage *bg = [[UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/MemUp.bundle/WeeAppBackground.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:71];
		UIImageView *bgView = [[UIImageView alloc] initWithImage:bg];
		bgView.frame = CGRectMake(0, 0, 314, 71);
		[_view addSubview:bgView];
        
        UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(freeMemory)];
        [_view addGestureRecognizer:tapRec];
        
		UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 316, 71)];
		lbl.backgroundColor = [UIColor clearColor];
		lbl.textColor = [UIColor whiteColor];
		lbl.text = @"Hello, World!";
		[_view addSubview:lbl];
	}

	return _view;
}

- (float)viewHeight
{
	return 71.0f;
}

- (void)showAlert:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
}

- (void)freeMemory {
    
    //const char* path = "/System/Library/WeeAppPlugins/MemUp.bundle/freemem";
    const char* path = "/Library/MemoryTap/freemem";

    int ret = 0;
    int n = 0;
    while (ret != 9) {
        ret = system(path);
        n++;
    }
    
    NSLog(@"n = %i", n);
    
}

@end