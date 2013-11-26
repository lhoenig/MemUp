//
//  MUTapGestureRecognizer.m
//  MemUp
//
//  Created by Lukas on 26.11.13.
//
//

#import "MUTapGestureRecognizer.h"

@implementation MUTapGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action

{
    self = [super initWithTarget:target action:action];
    
    if (self) {
        
       // self.numberOfTapsRequired = 1;
       // self.numberOfTouchesRequired = 1;
    }
    return self;
}


- (void)reset {
    [super reset];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;

{
    [super touchesBegan:touches withEvent:event];
}

@end
