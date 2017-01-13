//
//  HACRaw.m
//  Pods
//
//  Created by macbook on 17/1/12.
//
//

#import "HACRam.h"
#import "HACHelp.h"
#import "HACDeviceData.h"

#import <mach/mach.h>
#import <mach/mach_host.h>

@implementation HACRam {
}

+ (HACRamInfo *)getRamInfo {
    // basic information
    HACRamInfo *usage = [HACRamInfo new];
    usage.totalRam = [HACRam getRAMTotal];
    usage.ramType = [HACRam getRAMType];
    
    mach_port_t             host_port = mach_host_self();
    mach_msg_type_number_t  host_size = HOST_VM_INFO64_COUNT;
    vm_size_t               pageSize;
    vm_statistics64_data_t  vm_stat;
    
    //    if (host_page_size(host_port, &pageSize) != KERN_SUCCESS)
    //    {
    //        AMLogWarn(@"host_page_size() has failed - defaulting to 4K");
    //        pageSize = 4096;
    //    }
    // There is a crazy bug(?) on iPhone 5S causing host_page_size give 16384, but host_statistics64 provide statistics
    // relative to 4096 page size. For the moment it is relatively safe to hardcode 4096 here, but in the upcomming updates
    // it can misbehaves very badly.
    pageSize = 4096;
    
    if (host_statistics64(host_port, HOST_VM_INFO64, (host_info64_t)&vm_stat, &host_size) == KERN_SUCCESS) {
        usage.usedRam = (vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * pageSize;
        usage.activeRam = vm_stat.active_count * pageSize;
        usage.inactiveRam = vm_stat.inactive_count * pageSize;
        usage.wiredRam = vm_stat.wire_count * pageSize;
        usage.freeRam = usage.totalRam - usage.usedRam;
        usage.pageIns = vm_stat.pageins;
        usage.pageOuts = vm_stat.pageouts;
        usage.pageFaults = vm_stat.faults;
    } else {
        NSLog(@"host_statistics() has failed.");
    }
    return usage;
}

/** 获取当前应用的内存 */
+ (CGFloat)getUsedMemory {
    task_basic_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = MACH_TASK_BASIC_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(),
                                         TASK_BASIC_INFO, (task_info_t)&taskInfo, &infoCount);
    
    if(kernReturn != KERN_SUCCESS) {
        return 0;
    }
    
    return taskInfo.resident_size;
}

#pragma mark - private
+ (NSUInteger)getRAMTotal
{
    return (NSUInteger)[NSProcessInfo processInfo].physicalMemory;
}

+ (NSString*)getRAMType
{
    HACDeviceData *hardcodedData = [HACDeviceData sharedDeviceData];
    return (NSString*) [hardcodedData getRAMType];
}
@end
