//
//  MemUpController.h
//  MemUp
//
//  Created by Lukas on 25.11.13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BBWeeAppController.h"

@interface MemUpController : NSObject <BBWeeAppController>
{
    UIView *_view;
}

- (UIView *)view;

@end