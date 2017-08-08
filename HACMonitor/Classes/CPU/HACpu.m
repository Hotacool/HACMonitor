//
//  HACpu.m
//  Pods
//
//  Created by macbook on 17/1/12.
//
//

#import "HACpu.h"
#import "HACHelp.h"
#import "AMUtils.h"
#import "HACDeviceData.h"
#import "HACWeakObject.h"

#import <sys/sysctl.h>
#import <mach/mach_host.h>
#import <mach/machine.h>
#import <mach/task_info.h>
#import <mach/mach_types.h>
#import <mach/mach_init.h>
#import <mach/vm_map.h>
#import <mach/task.h>
#import <mach/thread_act.h>

@implementation HACpu {
    HACpuInfo *cpuInfo;
    
    processor_cpu_load_info_t priorCpuTicks;
    mach_port_t host;
    processor_set_name_port_t processorSet;
    
    NSTimer *timer;
    void(^monitorBlock)(CGFloat);
}

- (void)dealloc {
    [timer invalidate];
    timer = nil;
    
    free(priorCpuTicks);
}

- (instancetype)init {
    if (self = [super init]) {
        [self setUp];
    }
    return self;
}

- (void)setUp {
    // Set up mach host and default processor set for later calls.
    host = mach_host_self();
    processor_set_default(host, &processorSet);
    
    // Build the storage for the prior ticks and store the first block of data.
    natural_t cpuCount;
    processor_cpu_load_info_t processorTickInfo;
    mach_msg_type_number_t processorMsgCount;
    kern_return_t kStatus = host_processor_info(host, PROCESSOR_CPU_LOAD_INFO, &cpuCount,
                                                (processor_info_array_t*)&processorTickInfo, &processorMsgCount);
    if (kStatus == KERN_SUCCESS) {
        priorCpuTicks = malloc(cpuCount * sizeof(*priorCpuTicks));
        for (natural_t i = 0; i < cpuCount; ++i)
        {
            for (NSUInteger j = 0; j < CPU_STATE_MAX; ++j)
            {
                priorCpuTicks[i].cpu_ticks[j] = processorTickInfo[i].cpu_ticks[j];
            }
        }
        vm_deallocate(mach_task_self(), (vm_address_t)processorTickInfo, (vm_size_t)(processorMsgCount * sizeof(*processorTickInfo)));
    } else {
        NSLog(@"failure retreiving host_processor_info. kStatus == %d", kStatus);
    }
}

- (HACpuInfo *)getCpuInfo {
    if (HACObjectIsNull(cpuInfo)) {
        // set device
        HACDeviceData *hardcodeData = [HACDeviceData sharedDeviceData];
        NSString *hwMachine = [AMUtils getSysCtlChrWithSpecifier:"hw.machine"];
        [hardcodeData setHwMachine:hwMachine];
        // get cpu info
        cpuInfo = [[HACpuInfo alloc] init];
        cpuInfo.cpuName = [HACpu getCPUName];
    }
    cpuInfo.activeCPUCount = [HACpu getActiveCPUCount];
    cpuInfo.physicalCPUCount = [HACpu getPhysicalCPUCount];
    cpuInfo.physicalCPUMaxCount = [HACpu getPhysicalCPUMaxCount];
    cpuInfo.logicalCPUCount = [HACpu getLogicalCPUCount];
    cpuInfo.logicalCPUMaxCount = [HACpu getLogicalCPUMaxCount];
    cpuInfo.cpuFrequency = [HACpu getCPUFrequency];
    cpuInfo.l1DCache = [HACpu getL1DCache];
    cpuInfo.l1ICache = [HACpu getL1ICache];
    cpuInfo.l2Cache = [HACpu getL2Cache];
    cpuInfo.cpuType = [HACpu getCPUType];
    cpuInfo.cpuSubtype = [HACpu getCPUSubtype];
    cpuInfo.endianess = [HACpu getEndianess];
    return cpuInfo;
}

/** 获取应用当前的 CPU */
+ (CGFloat)getCpuUsageForTaskSelf {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return 0;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return 0;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return 0;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
    return tot_cpu;
}

- (NSArray<HACpuLoad*>*)getCpuUsageForAllProcessors {
    
    // host_info params
    unsigned int                processorCount;
    processor_cpu_load_info_t   processorTickInfo;
    mach_msg_type_number_t      processorMsgCount;
    // Errors
    kern_return_t               kStatus;
    // Loops
    unsigned int                i, j;
    // Data per proc
    unsigned long               system, user, nice, idle;
    unsigned long long          total, totalnonice;
    // Data average for all procs
    unsigned long long          systemall = 0;
    unsigned long long          userall = 0;
    unsigned long long          niceall = 0;
    unsigned long long          idleall = 0;
    unsigned long long          totalall = 0;
    unsigned long long          totalallnonice = 0;
    // Return data
    NSMutableArray *loadArr;
    NSUInteger activeCPUCount = [HACpu getActiveCPUCount];
    loadArr = [NSMutableArray arrayWithCapacity:activeCPUCount];
    for (NSUInteger i = 0; i < activeCPUCount; ++i) {
        [loadArr addObject:[[HACpuLoad alloc] init]];
    }
    
    if (!priorCpuTicks) {
        return loadArr;
    }
    // Read the current ticks
    kStatus = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processorCount,
                                  (processor_info_array_t*)&processorTickInfo, &processorMsgCount);
    if (kStatus != KERN_SUCCESS) {
        return loadArr;
    }
    
    loadArr = [NSMutableArray arrayWithCapacity:processorCount];
    
    // Loop the processors
    for (i = 0; i < processorCount; ++i)
    {
        // Calc load types and totals, with guards against overflows.
        
        if (processorTickInfo[i].cpu_ticks[CPU_STATE_SYSTEM] >= priorCpuTicks[i].cpu_ticks[CPU_STATE_SYSTEM])
        {
            system = processorTickInfo[i].cpu_ticks[CPU_STATE_SYSTEM] - priorCpuTicks[i].cpu_ticks[CPU_STATE_SYSTEM];
        }
        else
        {
            system = processorTickInfo[i].cpu_ticks[CPU_STATE_SYSTEM] + (ULONG_MAX - priorCpuTicks[i].cpu_ticks[CPU_STATE_SYSTEM] + 1);
        }
        
        if (processorTickInfo[i].cpu_ticks[CPU_STATE_USER] >= priorCpuTicks[i].cpu_ticks[CPU_STATE_USER])
        {
            user = processorTickInfo[i].cpu_ticks[CPU_STATE_USER] - priorCpuTicks[i].cpu_ticks[CPU_STATE_USER];
        }
        else
        {
            user = processorTickInfo[i].cpu_ticks[CPU_STATE_USER] + (ULONG_MAX - priorCpuTicks[i].cpu_ticks[CPU_STATE_USER] + 1);
        }
        
        if (processorTickInfo[i].cpu_ticks[CPU_STATE_NICE] >= priorCpuTicks[i].cpu_ticks[CPU_STATE_NICE])
        {
            nice = processorTickInfo[i].cpu_ticks[CPU_STATE_NICE] - priorCpuTicks[i].cpu_ticks[CPU_STATE_NICE];
        }
        else
        {
            nice = processorTickInfo[i].cpu_ticks[CPU_STATE_NICE] + (ULONG_MAX - priorCpuTicks[i].cpu_ticks[CPU_STATE_NICE] + 1);
        }
        
        if (processorTickInfo[i].cpu_ticks[CPU_STATE_IDLE] >= priorCpuTicks[i].cpu_ticks[CPU_STATE_IDLE])
        {
            idle = processorTickInfo[i].cpu_ticks[CPU_STATE_IDLE] - priorCpuTicks[i].cpu_ticks[CPU_STATE_IDLE];
        }
        else
        {
            idle = processorTickInfo[i].cpu_ticks[CPU_STATE_IDLE] + (ULONG_MAX - priorCpuTicks[i].cpu_ticks[CPU_STATE_IDLE] + 1);
        }
        
        total = system + user + nice + idle;
        totalnonice = system + user + idle;
        
        systemall += system;
        userall += user;
        niceall += nice;
        idleall += idle;
        totalall += total;
        totalallnonice += totalnonice;
        
        // Sanity
        if (total < 1)
        {
            total = 1;
        }
        if (totalnonice < 1)
        {
            totalnonice = 1;
        }
        
        HACpuLoad *loadObj            = [[HACpuLoad alloc] init];
        loadObj.system              = MIN(100.0, (double)system / total         * 100.0);
        loadObj.user                = MIN(100.0, (double)user   / total         * 100.0);
        loadObj.nice                = MIN(100.0, (double)nice   / total         * 100.0);
        loadObj.systemWithoutNice   = MIN(100.0, (double)system / totalnonice   * 100.0);
        loadObj.userWithoutNice     = MIN(100.0, (double)user   / totalnonice   * 100.0);
        loadObj.total               = loadObj.system + loadObj.user + loadObj.nice;
        [loadArr addObject:loadObj];
    }
    
    for (i = 0; i < processorCount; ++i)
    {
        for (j = 0; j < CPU_STATE_MAX; ++j)
        {
            priorCpuTicks[i].cpu_ticks[j] = processorTickInfo[i].cpu_ticks[j];
        }
    }
    
    vm_deallocate(mach_task_self(), (vm_address_t)processorTickInfo, (vm_size_t)(processorMsgCount * sizeof(*processorTickInfo)));
    
    return loadArr;
}

// 持续监控
- (BOOL)isActive {
    return (timer != nil);
}

- (BOOL)startCpuMonitorBlock:(void(^)(CGFloat))block {
    if (block) {
        monitorBlock = [block copy];
        timer = [NSTimer scheduledTimerWithTimeInterval:1 target:[HACWeakObject weakObjectWithTarget:self] selector:@selector(timerFire) userInfo:nil repeats:YES];
    }
    return NO;
}

- (void)stop {
    [timer invalidate];
    timer = nil;
}

- (void)timerFire {
    CGFloat cpu = [HACpu getCpuUsageForTaskSelf];
    monitorBlock(cpu);
}

#pragma mark - private
+ (NSString*)getCPUName
{
    HACDeviceData *hardcodeData = [HACDeviceData sharedDeviceData];
    return (NSString*)[hardcodeData getCPUName];
}

+ (NSUInteger)getActiveCPUCount
{
    return (NSUInteger)[AMUtils getSysCtl64WithSpecifier:"hw.activecpu"];
}

+ (NSUInteger)getPhysicalCPUCount
{
    return (NSUInteger)[AMUtils getSysCtl64WithSpecifier:"hw.physicalcpu"];
}

+ (NSUInteger)getPhysicalCPUMaxCount
{
    return (NSUInteger)[AMUtils getSysCtl64WithSpecifier:"hw.physicalcpu_max"];
}

+ (NSUInteger)getLogicalCPUCount
{
    return (NSUInteger)[AMUtils getSysCtl64WithSpecifier:"hw.logicalcpu"];
}

+ (NSUInteger)getLogicalCPUMaxCount
{
    return (NSUInteger)[AMUtils getSysCtl64WithSpecifier:"hw.logicalcpu_max"];
}

+ (NSUInteger)getCPUFrequency
{
    HACDeviceData *hardcodeData = [HACDeviceData sharedDeviceData];
    return [hardcodeData getCPUFrequency];
}

+ (NSUInteger)getL1ICache
{
    NSUInteger val = (NSUInteger)[AMUtils getSysCtl64WithSpecifier:"hw.l1icachesize"];
    if (val == -1)
    {
        val = 0;
    }
    {
        val = val;
    }
    return val;
}

+ (NSUInteger)getL1DCache
{
    NSUInteger val = (NSUInteger)[AMUtils getSysCtl64WithSpecifier:"hw.l1dcachesize"];
    if (val == -1)
    {
        val = 0;
    }
    {
        val = val;
    }
    return val;
}

+ (NSUInteger)getL2Cache
{
    NSUInteger val = (NSUInteger)[AMUtils getSysCtl64WithSpecifier:"hw.l2cachesize"];
    if (val == -1)
    {
        val = 0;
    }
    else
    {
        val = val;
    }
    return val;
}

+ (NSString*)getCPUType
{
    cpu_type_t cpuType = (cpu_type_t)[AMUtils getSysCtl64WithSpecifier:"hw.cputype"];
    return [self cpuTypeToString:cpuType];
}

+ (NSString*)getCPUSubtype
{
    cpu_subtype_t cpuSubtype = (cpu_subtype_t)[AMUtils getSysCtl64WithSpecifier:"hw.cpusubtype"];
    return [self cpuSubtypeToString:cpuSubtype];
}

+ (NSString*)getEndianess
{
    NSUInteger value = (NSUInteger)[AMUtils getSysCtl64WithSpecifier:"hw.byteorder"];
    
    if (value == 1234)
    {
        return @"Little endian";
    }
    else if (value == 4321)
    {
        return @"Big endian";
    }
    else
    {
        return @"-";
    }
}

+ (NSString*)cpuTypeToString:(cpu_type_t)cpuType
{
    switch (cpuType) {
        case CPU_TYPE_ANY:      return @"Unknown";          break;
        case CPU_TYPE_ARM:      return @"ARM";              break;
        case CPU_TYPE_HPPA:     return @"HP PA-RISC";       break;
        case CPU_TYPE_I386:     return @"Intel i386";       break;
        case CPU_TYPE_I860:     return @"Intel i860";       break;
        case CPU_TYPE_MC680x0:  return @"Motorola 680x0";   break;
        case CPU_TYPE_MC88000:  return @"Motorola 88000";   break;
        case CPU_TYPE_MC98000:  return @"Motorola 98000";   break;
        case CPU_TYPE_POWERPC:  return @"Power PC";         break;
        case CPU_TYPE_POWERPC64:return @"Power PC64";       break;
        case CPU_TYPE_SPARC:    return @"SPARC";            break;
        default:                return @"Unknown";          break;
    }
}

+ (NSString*)cpuSubtypeToString:(cpu_subtype_t)cpuSubtype
{
    switch (cpuSubtype) {
        case CPU_SUBTYPE_ARM_ALL:   return @"ARM";          break;
        case CPU_SUBTYPE_ARM_V4T:   return @"ARMv4T";       break;
        case CPU_SUBTYPE_ARM_V5TEJ: return @"ARMv5TEJ";     break;
        case CPU_SUBTYPE_ARM_V6:    return @"ARMv6";        break;
        case CPU_SUBTYPE_ARM_V7:    return @"ARMv7";        break;
        case CPU_SUBTYPE_ARM_V7F:   return @"ARMv7F";       break;
        case CPU_SUBTYPE_ARM_V7K:   return @"ARMv7K";       break;
        case CPU_SUBTYPE_ARM_V7S:   return @"ARMv7S";       break;
#if !(TARGET_IPHONE_SIMULATOR) // Simulator headers don't include such subtype.
        case CPU_SUBTYPE_ARM64_V8:  return @"ARM64";        break;
#endif
        default:                    return @"Unknown";      break;
    }
}
@end
