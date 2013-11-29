//
//  MemUpController.m
//  MemUp
//
//  Created by Lukas on 25.11.13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#define BYTE_TO_MB 1048576

//temporary - solution depends on orientation change handling
#define VIEW_WIDTH 316
#define VIEW_HEIGHT 45

#define ANIM_FADE_DUR 0.2
#define ANIM_UPDATE_UI_DUR 1

#define UI_UPDATE_IVAL 5

#define USEDVIEW_OPACITY 0.4
#define OVERLAY_VIEW_OPACITY 0.7
#define BORDER_ALPHA 1

#define LEFT_VIEW_OFFSET_PX 2

#import "MemUpController.h"
#import <mach/mach.h>
#import <mach/mach_host.h>

@implementation MemUpController

// Absolute height of widget
- (float)viewHeight {
    return VIEW_HEIGHT;
}

- (UIView *)view
{
	if (_view == nil)
	{
        // TODO: handle orientation changes in terms of layout/frame
        _view = [[UIView alloc] initWithFrame:CGRectMake(LEFT_VIEW_OFFSET_PX, 0, VIEW_WIDTH, VIEW_HEIGHT)];
        _view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        // Background view
		UIImage *bg = [[UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/MemUp.bundle/WeeAppBackground.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:71];
		UIImageView *bgView = [[UIImageView alloc] initWithImage:bg];
		bgView.frame = CGRectMake(0, 0, 316, VIEW_HEIGHT);
		[_view addSubview:bgView];
        
        _pressRec = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
        _pressRec.numberOfTouchesRequired = 1;
        _pressRec.minimumPressDuration = 0.1f;
        _pressRec.allowableMovement = 5.0f;
        _pressRec.delegate = self;
        [_view addGestureRecognizer:_pressRec];
        
        // On-tap overlay view and label
        CGRect modFrame = _view.frame;
        modFrame.origin.x -= 2;
        modFrame.size.height -= 1;
        dimView = [[UIView alloc] initWithFrame:modFrame];
        dimView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:OVERLAY_VIEW_OPACITY];
        dimView.layer.cornerRadius = 5.0f;
        
        UILabel *dimViewLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        dimViewLabel.backgroundColor = [UIColor clearColor];
		dimViewLabel.textAlignment = UITextAlignmentCenter;
        dimViewLabel.textColor = [UIColor whiteColor];
        dimViewLabel.font = [UIFont boldSystemFontOfSize:18];
        dimViewLabel.text = @"Free";
        dimViewLabel.frame = CGRectMake(0,
                                        (VIEW_HEIGHT / 2) - ([dimViewLabel.text sizeWithFont:dimViewLabel.font].height / 2),
                                        dimView.frame.size.width,
                                        [dimViewLabel.text sizeWithFont:dimViewLabel.font].height);
        dimView.alpha = 0;
        [dimView addSubview:dimViewLabel];
        [dimView bringSubviewToFront:dimViewLabel];
        
        
        // Memory usage indicator view and label
        usedMemoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT - 1)];
        usedMemoryView.backgroundColor = [UIColor blackColor];
        usedMemoryView.layer.opacity = USEDVIEW_OPACITY;
        usedMemoryView.layer.cornerRadius = 5.0f;
        //usedMemoryView.layer.borderWidth = 1.0f;
        //usedMemoryView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:BORDER_ALPHA].CGColor;

		lbl = [[UILabel alloc] initWithFrame:CGRectNull];
        lbl.contentMode = UIViewContentModeScaleToFill; // to fix label not-animating issue
		lbl.backgroundColor = [UIColor clearColor];
		lbl.textAlignment = UITextAlignmentCenter;
        lbl.textColor = [UIColor whiteColor];
        lbl.font = [UIFont boldSystemFontOfSize:24];
        
        // Activity indicator
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        indicator.frame = CGRectMake((_view.frame.size.width / 2) - (indicator.frame.size.width / 2),
                                     (_view.frame.size.height / 2) - (indicator.frame.size.height / 2) + 1,
                                     indicator.frame.size.height - 4,
                                     indicator.frame.size.width - 4);
        indicator.alpha = 0;
        
        [self updateUIComponents:NO];
        [_view addSubview:usedMemoryView];
        [_view addSubview:lbl];
        [dimView addSubview:indicator];
        [_view addSubview:dimView];
        
        [self startUpdateTimer:UI_UPDATE_IVAL];
    }
	return _view;
}

- (void)handlePress:(UITapGestureRecognizer *)sender
{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            dimView.layer.opacity = OVERLAY_VIEW_OPACITY;
            [_view bringSubviewToFront:dimView];
            break;
        case UIGestureRecognizerStateEnded:
            dimView.layer.opacity = 0;
            [_view sendSubviewToBack:dimView];
            [self freeMemoryAction];
            break;
        case UIGestureRecognizerStateFailed:
            dimView.layer.opacity = 0;
            [_view sendSubviewToBack:dimView];
        case UIGestureRecognizerStateCancelled:
            dimView.layer.opacity = 0;
            [_view sendSubviewToBack:dimView];
            break;
        default:
            break;
    }
    NSLog(@"State: %i", sender.state);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

- (void)updateUIComponents:(BOOL)animated {
    
    float used_memory = (float)abs(free_mem_bytes()) / (float)[self physicalMemory];
    float used_reverse = 1 - used_memory;
    
    [self updateLabelText];
    
    [UIView animateWithDuration:animated ? ANIM_UPDATE_UI_DUR : 0 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        usedMemoryView.frame = CGRectMake(usedMemoryView.frame.origin.x,
                                          usedMemoryView.frame.origin.y,
                                          VIEW_WIDTH * used_reverse,
                                          usedMemoryView.frame.size.height);
        
        lbl.frame = CGRectMake(((usedMemoryView.frame.size.width / 2) - ([lbl.text sizeWithFont:lbl.font].width / 2)),
                               (VIEW_HEIGHT / 2) - ([lbl.text sizeWithFont:lbl.font].height / 2),
                               [lbl.text sizeWithFont:lbl.font].width,
                               [lbl.text sizeWithFont:lbl.font].height);

    } completion:^(BOOL finished){}];
}

- (void)updateLabelText {
    int totalMemMB = (int)((float)[self physicalMemory] / BYTE_TO_MB);
    
    //lbl.text = [NSString stringWithFormat:@"%llu / %i", ([self getPhysicalMemoryValue] / BYTE_TO_MB) - ((int)(free_mem_bytes() / BYTE_TO_MB)), totalMemMB];
    lbl.text = [NSString stringWithFormat:@"%llu", ([self physicalMemory] / BYTE_TO_MB) - ((int)(free_mem_bytes() / BYTE_TO_MB))];
}


- (void)startUpdateTimer:(NSTimeInterval)ival {
    // reset 5s period to UI update
    if (updateTimer) {
        [updateTimer invalidate];
    }
    updateTimer = [NSTimer timerWithTimeInterval:UI_UPDATE_IVAL target:self selector:@selector(updateUIComponents:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:updateTimer forMode:NSDefaultRunLoopMode];
}


// wrapper for logging purposes
- (void)showAlert:(NSString *)message {
    [ [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}

// Log macro
void muLog(NSString *string) {
    NSLog(@"memup: %@", string);
}

- (unsigned long long)physicalMemory{
    return [[NSProcessInfo processInfo] physicalMemory];
}


- (void)freeMemoryAction {
    
    _pressRec.enabled = NO;
    
    muLog(@"freeing memory.");
    
    //[indicator startAnimating];
    //[UIView animateWithDuration:ANIM_FADE_DUR animations:^{
        //lbl.alpha = 0;
        //indicator.alpha = 1;
    //} completion:^(BOOL finished){
        
        //logMemStats();
        NSDate *methodStart = [NSDate date];
        int times = [self freememLoop];
        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
        NSLog(@"memup: finished in %.2fs", executionTime /*, times */);
        //logMemStats();
    
        /*
        [UIView animateWithDuration:ANIM_FADE_DUR delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            
            //lbl.alpha = 1;
            //indicator.alpha = 0;
        } completion:^(BOOL finished){
        */
            //[indicator stopAnimating];
    
            [self startUpdateTimer:UI_UPDATE_IVAL];
            [self updateUIComponents:YES];
            _pressRec.enabled = YES;
    
        //}];
    //}];
}

- (int)freememLoop {
    int ret = 0;
    int n = 0;
    while (ret != 9 && n <= 5) {
        ret = system("/System/Library/WeeAppPlugins/MemUp.bundle/freemem");
        // muLog(@"Return code: %i", ret);
        n++;
    }
    return n;
}


// Memory calculation functions

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
        muLog(@"Failed to fetch vm statistics");
    
    /* Stats in bytes */
    natural_t mem_used = (vm_stat.active_count +
                          vm_stat.inactive_count +
                          vm_stat.wire_count) * pagesize;
    
    natural_t mem_free = vm_stat.free_count * pagesize;
    natural_t mem_total = mem_used + mem_free;
    
    return mem_free;
}

void logMemStats() {
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    vm_statistics_data_t vm_stat;
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
        muLog(@"Failed to fetch vm statistics");

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