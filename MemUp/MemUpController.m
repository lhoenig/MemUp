//
//  MemUpController.m
//  MemUp
//
//  Created by Lukas on 25.11.13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#define VIEW_HEIGHT 49

#import "MemUpController.h"
#import <mach/mach.h>
#import <mach/mach_host.h>

@implementation MemUpController


- (void)showAlert:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}

- (float)viewHeight
{
	return VIEW_HEIGHT;
}

- (UIView *)view
{
	if (_view == nil)
	{
		_view = [[UIView alloc] initWithFrame:CGRectMake(2, 0, 316, 28)];
        
		UIImage *bg = [[UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/MemUp.bundle/WeeAppBackground.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:71];
		UIImageView *bgView = [[UIImageView alloc] initWithImage:bg];
		bgView.frame = CGRectMake(0, 0, 316, VIEW_HEIGHT);
		[_view addSubview:bgView];
        
        _tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(freeMemory)];
        [_view addGestureRecognizer:_tapRec];
        
		lbl = [[UILabel alloc] initWithFrame:CGRectNull];
		lbl.backgroundColor = [UIColor clearColor];
		lbl.textAlignment = UITextAlignmentCenter;
        lbl.textColor = [UIColor whiteColor];
		lbl.text = [NSString stringWithFormat:@"%i", (int)(free_mem()/1048576)];
        lbl.font = [UIFont boldSystemFontOfSize:19];
		lbl.frame = CGRectMake(0, 8, 316, 28);
        [_view addSubview:lbl];
        
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicator.frame = CGRectMake(0, 0, 20, 20);
        indicator.frame = CGRectMake((_view.frame.size.width / 2) - (indicator.frame.size.width / 2),
                                     (_view.frame.size.height / 2) - (indicator.frame.size.height / 2) + 11,
                                     indicator.frame.size.height - 3,
                                     indicator.frame.size.width - 3);
        indicator.alpha = 0;
        [_view addSubview:indicator];
    }

	return _view;
}

- (void)freeMemory {
    
    _tapRec.enabled = NO;
    NSLog(@"memup: freeing memory.");
    
    [indicator startAnimating];
    [UIView animateWithDuration:0.3 animations:^{
        lbl.alpha = 0;
        indicator.alpha = 1;
    } completion:^(BOOL finished){
        NSLog(@"after animaion block");
        NSDate *methodStart = [NSDate date];
        
        int ret = 0;
        int n = 0;
        while (ret != 9 && n <= 5) {
            ret = system("/System/Library/WeeAppPlugins/MemUp.bundle/freemem");
            // NSLog(@"Return code: %i", ret);
            n++;
        }
        
        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
        NSLog(@"memup: finished freeing memory in %fs", executionTime);
        lbl.text = [NSString stringWithFormat:@"%i", (int)(free_mem()/1048576)];
        [UIView animateWithDuration:0.4 animations:^{
            lbl.alpha = 1;
            indicator.alpha = 0;
        }];
        [indicator stopAnimating];
        _tapRec.enabled = YES;
    }];
}

unsigned int free_mem()
{
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    
    vm_statistics_data_t vm_stat;
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
        NSLog(@"Failed to fetch vm statistics");
    
    /* Stats in bytes */
    /*
    natural_t mem_used = (vm_stat.active_count +
                          vm_stat.inactive_count +
                          vm_stat.wire_count) * pagesize;
    */
    natural_t mem_free = vm_stat.free_count * pagesize;
    //natural_t mem_total = mem_used + mem_free;
    return mem_free;
}



@end