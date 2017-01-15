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
#import <HACMonitor/HACBattery.h>
#import <HACMonitor/HACNetwork.h>

@interface HACViewController ()

@end

@implementation HACViewController {
    HACpu *cpu;
    HACBattery *battery;
    HACNetwork *network;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    cpu = [HACpu new];
    HACpuInfo *cpuInfo = [cpu getCpuInfo];
    NSLog(@"cpuInfo: %@", [cpuInfo description]);
//
//    HACRamInfo *ramInfo = [HACRam getRamInfo];
//    NSLog(@"ramInfo: %@", [ramInfo description]);

    battery = [HACBattery new];
    HACBatteryInfo *batteryInfo = [battery getBatteryInfo];
    NSLog(@"batteryInfo: %@", [batteryInfo description]);
    NSLog(@"battery level: %d", [HACBattery getCurrentBatteryLevel]);
    [battery startBatteryMonitoring];
    
    network = [HACNetwork new];
    [network getNetworkInfo];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(NetworkStatusUpdated) name:kHACNetworkStatusUpdated object:nil];
    
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
    NSArray *arr = [cpu getCpuUsageForAllProcessors];
    if (arr.count < 1) {
        return;
    }
    [arr enumerateObjectsUsingBlock:^(HACpuLoad * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        sum += obj.total;
//        NSLog(@"cup load: %@", [obj description]);
    }];
    NSLog(@"getCpuUsageForAllProcessors: %f", sum);
//    NSLog(@"used memory: %f", [HACRam getUsedMemory]/1024/1024);
    NSLog(@"batteryInfo: %@", [[battery getBatteryInfo] description]);
    
    NSLog(@"network info: %@", [network getNetworkInfo]);
    
    NSLog(@"network flow: %@", [HACNetwork getNetworkFlow]);
}

- (void)NetworkStatusUpdated {
    NSLog(@"network info: %@", [network getNetworkInfo]);
}

@end
