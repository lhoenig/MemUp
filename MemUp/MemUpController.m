//
//  MemUpController.m
//  MemUp
//
//  Created by Lukas on 25.11.13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#define VIEW_HEIGHT 51
#define BYTE_TO_MB 1048576
#define ANIM_FADE_DUR 0.38
#define ANIM_FADE2_DUR 0.3
#define UPDATE_IVAL 10
#define USEDVIEW_OPACITY 0.36

#import "MemUpController.h"
#import <mach/mach.h>
#import <mach/mach_host.h>

@implementation MemUpController

- (UIView *)view
{
	if (_view == nil)
	{
		NSLog(NSStringFromCGRect([UIScreen mainScreen].bounds));
        _view = [[UIView alloc] initWithFrame:CGRectMake(2, 0, 316, VIEW_HEIGHT)];
        // TODO: handle orientation changes in terms of layout/frame
        
		UIImage *bg = [[UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/MemUp.bundle/WeeAppBackground.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:71];
		UIImageView *bgView = [[UIImageView alloc] initWithImage:bg];
		bgView.frame = CGRectMake(0, 0, 316, VIEW_HEIGHT);
		[_view addSubview:bgView];
        
        usedMemoryView = [[UIView alloc] initWithFrame:CGRectMake(3, 3, 200, VIEW_HEIGHT - 7)];
        usedMemoryView.backgroundColor = [UIColor blackColor];
        usedMemoryView.layer.opacity = USEDVIEW_OPACITY;
        usedMemoryView.layer.cornerRadius = 3.0f;
        
        _tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(freeMemory)];
        _tapRec.delegate = self;
        [_view addGestureRecognizer:_tapRec];
        
		lbl = [[UILabel alloc] initWithFrame:CGRectNull];
		lbl.backgroundColor = [UIColor clearColor];
		lbl.textAlignment = UITextAlignmentCenter;
        lbl.textColor = [UIColor whiteColor];
        lbl.font = [UIFont boldSystemFontOfSize:24];
		lbl.frame = CGRectMake(0, (VIEW_HEIGHT / 2) - 14, _view.frame.size.width, 28);
        
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicator.frame = CGRectMake((_view.frame.size.width / 2) - (indicator.frame.size.width / 2),
                                     (_view.frame.size.height / 2) - (indicator.frame.size.height / 2) + 2,
                                     indicator.frame.size.height - 4,
                                     indicator.frame.size.width - 4);
        
        indicator.alpha = 0;
        
        [self updateUIComponents:NO];
        [_view addSubview:usedMemoryView];
        [_view addSubview:lbl];
        [_view addSubview:indicator];
        [self startUpdateTimer:UPDATE_IVAL];
    }

	return _view;
}


-(unsigned long long)getPhysicalMemoryValue{
    return [[NSProcessInfo processInfo] physicalMemory];
}


- (void)updateUIComponents:(BOOL)animated {
    [self updateLabelText];
    [self updateUsedMemoryView:animated];
}

- (void)updateLabelText {
    int totMemMB = (int)((float)[self getPhysicalMemoryValue] / BYTE_TO_MB);
    lbl.text = [NSString stringWithFormat:@"%llu / %i", ([self getPhysicalMemoryValue] / BYTE_TO_MB) - ((int)(free_mem_bytes() / BYTE_TO_MB)), totMemMB];
}

- (void)updateUsedMemoryView:(BOOL)animated {
    float used_memory = (float)abs(free_mem_bytes()) / (float)[self getPhysicalMemoryValue];
    float used_reverse = 1 - used_memory;
    [UIView animateWithDuration:animated ? ANIM_FADE2_DUR : 0  animations:^{
        usedMemoryView.frame = CGRectMake(usedMemoryView.frame.origin.x, usedMemoryView.frame.origin.y, (_view.frame.size.width - 6) * used_reverse, usedMemoryView.frame.size.height);
    }];
}


- (void)showAlert:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}


- (float)viewHeight
{
	return VIEW_HEIGHT;
}


- (void)startUpdateTimer:(NSTimeInterval)ival {
    // reset 5s period to UI update
    if (updateTimer) {
        [updateTimer invalidate];
    }
    updateTimer = [NSTimer timerWithTimeInterval:UPDATE_IVAL target:self selector:@selector(updateUIComponents:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:updateTimer forMode:NSDefaultRunLoopMode];
}


- (void)freeMemory {
    
    _tapRec.enabled = NO;
    
    NSLog(@"memup: freeing memory.");
    
    [indicator startAnimating];
    [UIView animateWithDuration:ANIM_FADE_DUR animations:^{
        lbl.alpha = 0;
        indicator.alpha = 1;
    } completion:^(BOOL finished){
        
        //logMemStats();
        NSDate *methodStart = [NSDate date];
        int times = [self freememLoop];
        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
        NSLog(@"memup: finished freeing memory in %.2fs", executionTime, times);
        //logMemStats();
        
        [self updateLabelText];
        [UIView animateWithDuration:ANIM_FADE_DUR animations:^{
            lbl.alpha = 1;
            indicator.alpha = 0;
        } completion:^(BOOL finished){
            [indicator stopAnimating];
            [self startUpdateTimer:UPDATE_IVAL];
            _tapRec.enabled = YES;
        }];
    }];
}


- (int)freememLoop {
    int ret = 0;
    int n = 0;
    while (ret != 9 && n <= 5) {
        ret = system("/System/Library/WeeAppPlugins/MemUp.bundle/freemem");
        // NSLog(@"Return code: %i", ret);
        n++;
    }
    return n;
}

unsigned int free_mem_bytes()
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
    natural_t mem_used = (vm_stat.active_count +
                          vm_stat.inactive_count +
                          vm_stat.wire_count) * pagesize;
    
    natural_t mem_free = vm_stat.free_count * pagesize;
    natural_t mem_total = mem_used + mem_free;
    
    return mem_free;
}

//unsigned int totalMemory()
//{
//    mach_port_t host_port;
//    mach_msg_type_number_t host_size;
//    vm_size_t pagesize;
//    
//    host_port = mach_host_self();
//    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
//    host_page_size(host_port, &pagesize);
//    
//    vm_statistics_data_t vm_stat;
//    
//    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
//        NSLog(@"Failed to fetch vm statistics");
//    
//    /* Stats in bytes */
//    natural_t mem_used = (vm_stat.active_count +
//                          vm_stat.inactive_count +
//                          vm_stat.wire_count) * pagesize;
//    
//    natural_t mem_free = vm_stat.free_count * pagesize;
//    natural_t mem_total = mem_used + mem_free;
//    
//    return mem_total;
//}


void logMemStats() {
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    vm_statistics_data_t vm_stat;
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
        NSLog(@"Failed to fetch vm statistics");

    natural_t mem_used = (vm_stat.active_count +
                          vm_stat.inactive_count +
                          vm_stat.wire_count) * pagesize;
    natural_t mem_free = vm_stat.free_count * pagesize;
    natural_t mem_total = mem_used + mem_free;
    natural_t mem_free_alt = mem_total - mem_used;
    NSLog(@"Memory statistics:");
    NSLog(@"mem_used= %u");
    NSLog(@"mem_free= %u", mem_free);
    NSLog(@"mem_total= %u", mem_total);
    NSLog(@"mem_free_alt= %u", mem_free_alt);
    NSLog(@"active_count= %u", vm_stat.active_count * pagesize);
    NSLog(@"inactive_count= %u", vm_stat.inactive_count * pagesize);
    NSLog(@"wire_count= %u",vm_stat.wire_count * pagesize);
}


@end