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
#define VIEW_HEIGHT 47

#define ANIM_FADE_DUR 0.2
#define ANIM_UPDATE_UI_DUR 1.0

#define UI_UPDATE_IVAL 10

#define USEDVIEW_OPACITY 0.4
#define BTN_HIGHLIGHT_OPACITY 0.8

#define SUBVIEW_INSET 2

#import "MemUpController.h"
#import <mach/mach.h>
#import <mach/mach_host.h>
#import "Logging.h"


@implementation MemUpController


// Absolute height of widget
- (float)viewHeight {
    return VIEW_HEIGHT;
}


- (void)willAnimateRotationToInterfaceOrientation:(int)interfaceOrientation {
    
    // TODO: remove layout bug on first show after installing
    
    NSString * const orientations[] = {
        @"Unknown",
        @"Portrait",
        @"PortraitUpsideDown",
        @"LandscapeLeft",
        @"LandscapeRight"
    };
    LogDebug(@"memup: will animate to %i (%@)", interfaceOrientation, orientations[interfaceOrientation]);
    
    // Layout subviews' frames
    
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGRect baseRect = CGRectMake(0,
                                 0,
                                 UIInterfaceOrientationIsPortrait(interfaceOrientation) ? bounds.size.width : bounds.size.height,
                                 VIEW_HEIGHT);
    
    _view.frame = baseRect;
    
    bgView.frame = CGRectMake(SUBVIEW_INSET,
                              0,
                              baseRect.size.width - 2 * SUBVIEW_INSET,
                              baseRect.size.height);
    
    btn.frame = CGRectMake(SUBVIEW_INSET,
                           0,
                           baseRect.size.width - 2 * SUBVIEW_INSET,
                           baseRect.size.height - 1);
    
    UIImage *image = [self createImageWithSize:btn.frame.size color:[[UIColor blackColor] colorWithAlphaComponent:BTN_HIGHLIGHT_OPACITY]];
    [btn setBackgroundImage:image forState:UIControlStateHighlighted];
    
    
    usedMemoryView.frame = CGRectMake(SUBVIEW_INSET,
                                      0,
                                      baseRect.size.width - 2 * SUBVIEW_INSET,
                                      baseRect.size.height - 1);
    
    [self updateUIComponents];
    
    //[self screenBoundsComparison:_view];
    //[self screenBoundsComparison:bgView];
}

- (void)viewWillAppear {
    [self readPreferences];
}

- (UIView *)view {
    
    // This is called once on startup
    
	if (_view == nil)
	{
        LogDebug(@"memup: _view == nil");

        _view = [[UIView alloc] initWithFrame:CGRectZero];
        _view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        // Background image view
        UIImage *bg = [[UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/MemUp.bundle/WeeAppBackground.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
		bgView = [[UIImageView alloc] initWithImage:bg];
		bgView.frame = CGRectZero;
        bgView.layer.cornerRadius = 5.0f;
        bgView.layer.masksToBounds = YES;
        // old layout code
        //bgView.frame = CGRectMake(0, 0, _view.frame.size.width, _view.frame.size.height);
        //bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		
        [_view addSubview:bgView];

        
        // Free memory button
        btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.backgroundColor = [UIColor clearColor];
        btn.layer.cornerRadius = 4.0f;
        btn.layer.masksToBounds = YES;
        [btn setTitle:@"" forState:UIControlStateNormal];
        [btn setTitle:@"Free" forState:UIControlStateHighlighted];
        
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:25];
        [btn addTarget:self action:@selector(freeMemoryAction) forControlEvents:UIControlEventTouchUpInside];
        
        [_view addSubview:btn];
        
        
        // Memory usage indicator view and label
        usedMemoryView = [[UIView alloc] initWithFrame:CGRectZero];
        //usedMemoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT - 1)];
        usedMemoryView.backgroundColor = [UIColor blackColor];
        usedMemoryView.layer.opacity = USEDVIEW_OPACITY;
        usedMemoryView.layer.cornerRadius = 5.0f;
        
        [_view addSubview:usedMemoryView];

        
        
		lbl = [[UILabel alloc] initWithFrame:CGRectNull];
        lbl.contentMode = UIViewContentModeScaleToFill;  // to fix label not-animating issue
		lbl.backgroundColor = [UIColor clearColor];
		lbl.textAlignment = UITextAlignmentCenter;  //use of deperecated method because we're developing for <= iOS6
        lbl.textColor = [UIColor whiteColor];
        lbl.font = [UIFont boldSystemFontOfSize:24];
        [_view addSubview:lbl];
        
        //[self updateUIComponents];
        [self readPreferences];

        [_view bringSubviewToFront:btn];
        
        [self startUpdateTimer:UI_UPDATE_IVAL];
    }
	return _view;
}

- (void)readPreferences {
    nmax = (int)[[NSUserDefaults standardUserDefaults] valueForKey:@"\"Slider_NumberOfTimes\""];
    LogDebug(@"value = %i", nmax);
    
    NSArray *path = NSSearchPathForDirectoriesInDomains(
                                                        NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *folder = [path objectAtIndex:0];
    NSLog(@"Your NSUserDefaults are stored in this folder: %@/Preferences", folder);
}

- (void)updateUIComponents {
    
    LogDebug(@"memup: updating UI");
    
    float used_memory = (float)abs(free_mem_bytes()) / (float)[self physicalMemory];
    float used_reverse = 1 - used_memory;

    lbl.text = [self constructLabelText];

    usedMemoryView.frame = CGRectMake(usedMemoryView.frame.origin.x,
                                      usedMemoryView.frame.origin.y,
                                      _view.frame.size.width * used_reverse,
                                      usedMemoryView.frame.size.height);
    
    lbl.frame = CGRectMake(((usedMemoryView.frame.size.width / 2) - ([lbl.text sizeWithFont:lbl.font].width / 2)),
                           (VIEW_HEIGHT / 2) - ([lbl.text sizeWithFont:lbl.font].height / 2),
                           [lbl.text sizeWithFont:lbl.font].width,
                           [lbl.text sizeWithFont:lbl.font].height);
}


- (void)updateUIComponentsAnimated {
    
    LogDebug(@"memup: updating UI animated");
    
    float used_memory = (float)abs(free_mem_bytes()) / (float)[self physicalMemory];
    float used_reverse = 1 - used_memory;
    
    // TODO: fix transition fading the label
    /*
    CATransition *animation = [CATransition animation];
    animation.duration = ANIM_UPDATE_UI_DUR;
    animation.type = kCATransitionFade;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [lbl.layer addAnimation:animation forKey:@"changeTextTransition"];
    */
    lbl.text = [self constructLabelText]; // change text using CATransition

    [UIView animateWithDuration:ANIM_UPDATE_UI_DUR delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        usedMemoryView.frame = CGRectMake(usedMemoryView.frame.origin.x,
                                          usedMemoryView.frame.origin.y,
                                          _view.frame.size.width * used_reverse,
                                          usedMemoryView.frame.size.height);
        
        lbl.frame = CGRectMake(((usedMemoryView.frame.size.width / 2) - ([lbl.text sizeWithFont:lbl.font].width / 2)),
                               (VIEW_HEIGHT / 2) - ([lbl.text sizeWithFont:lbl.font].height / 2),
                               [lbl.text sizeWithFont:lbl.font].width,
                               [lbl.text sizeWithFont:lbl.font].height);
        
    } completion:^(BOOL finished){}];
}


- (NSString *)constructLabelText {
    int totalMemMB = (int)((float)[self physicalMemory] / BYTE_TO_MB);
    
    //lbl.text = [NSString stringWithFormat:@"%llu / %i", ([self getPhysicalMemoryValue] / BYTE_TO_MB) - ((int)(free_mem_bytes() / BYTE_TO_MB)), totalMemMB]; // label format: "120 / 1004"
    return [NSString stringWithFormat:@"%llu", ([self physicalMemory] / BYTE_TO_MB) - ((int)(free_mem_bytes() / BYTE_TO_MB))];
}


- (void)startUpdateTimer:(NSTimeInterval)ival {
    // reset 5s period to UI update
    if (updateTimer) {
        [updateTimer invalidate];
    }
    updateTimer = [NSTimer timerWithTimeInterval:UI_UPDATE_IVAL target:self selector:@selector(updateUIComponentsAnimated) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:updateTimer forMode:NSDefaultRunLoopMode];
}


- (void)screenBoundsComparison:(UIView *)view {
    LogInfo(@"%@", [NSString stringWithFormat:@"memup: %@ =\t%@, screen bounds = %@",
                    NSStringFromClass(view.class), NSStringFromCGRect(view.frame), NSStringFromCGRect([UIScreen mainScreen].bounds)]);
}


- (UIImage *)createImageWithSize:(CGSize)size color:(UIColor *)color {
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [color setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    /*
     // create our blurred image
     CIContext *context = [CIContext contextWithOptions:nil];
     CIImage *inputImage = [CIImage imageWithCGImage:image.CGImage];
     
     // setting up Gaussian Blur (we could use one of many filters offered by Core Image)
     CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
     [filter setValue:inputImage forKey:kCIInputImageKey];
     [filter setValue:[NSNumber numberWithFloat:10.0f] forKey:@"inputRadius"];
     CIImage *result = [filter valueForKey:kCIOutputImageKey];
     
     // CIGaussianBlur has a tendency to shrink the image a little,
     // this ensures it matches up exactly to the bounds of our original image
     CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];
     
     //return [UIImage imageWithCGImage:cgImage];
    */
    
    return image;
}


// simulate memory usage
- (void)useMemoryByAllocatingImages:(int)n {
    LogDebug(@"memup: Allocating %i images.", n);
    
    NSMutableArray *a = [[NSMutableArray alloc] init];
    for (int i = 0; i < n; i++) {
        [a addObject:[self createImageWithSize:CGSizeMake(100, 100) color:[UIColor blackColor]]];
    }
}


/*
- (void)freeMemoryActionWrapper {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self freeMemoryAction]; });
}
*/

- (void)freeMemoryAction {
    
    LogInfo(@"memup: freeing memory.");

    //logMemStats();
    NSDate *methodStart = [NSDate date];
    int times = [self freememLoop];
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    LogDebug(@"memup: finished in %.2fs, n=%i", executionTime , times);
    //logMemStats();
        
    [self startUpdateTimer:UI_UPDATE_IVAL];
    [self updateUIComponentsAnimated];
}


// Core functionality
- (int)freememLoop {
    int ret = 0;
    int n = 0;
    while (ret != 9 && n <= 4) {
        ret = system("/System/Library/WeeAppPlugins/MemUp.bundle/freemem");
        LogTrace(@"memup: return code: %i", ret);
        n++;
    }
    
    return n;   // return number of times the executable ran
}


// Memory calculations

- (unsigned long long)physicalMemory{
    return [[NSProcessInfo processInfo] physicalMemory];
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
        LogError(@"Failed to fetch vm statistics");
    
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
        LogError(@"Failed to fetch vm statistics");
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


- (void)showAlert:(NSString *)message {
    [ [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}

@end