//
//  HACViewController.m
//  HACMonitor
//
//  Created by sicong.qian on 01/12/2017.
//  Copyright (c) 2017 sicong.qian. All rights reserved.
//

#import "HACViewController.h"
#import <HACMonitor/HACpu.h>
#import <HACMonitor/HACRam.h>

@interface HACViewController ()

@end

@implementation HACViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    HACpuInfo *cpuInfo = [HACpu getCpuInfo];
    NSLog(@"cpuInfo: %@", [cpuInfo description]);
    
    HACRamInfo *ramInfo = [HACRam getRamInfo];
    NSLog(@"ramInfo: %@", [ramInfo description]);
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(doSomething) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)doSomething {
    NSLog(@"getCpuUsageForTaskSelf: %f", [HACpu getCpuUsageForTaskSelf]);
    double __block sum;
    NSArray *arr = [HACpu getCpuUsageForAllProcessors];
    if (arr.count < 1) {
        return;
    }
    [arr enumerateObjectsUsingBlock:^(HACpuLoad * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        sum += obj.total;
//        NSLog(@"cup load: %@", [obj description]);
    }];
    NSLog(@"getCpuUsageForAllProcessors: %f", sum);
    
    NSLog(@"ramInfo: %@", [[HACRam getRAMUsage] description]);
    NSLog(@"used memory: %f", [HACRam getUsedMemory]/1024/1024);
}

@end
