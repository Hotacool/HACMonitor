//
//  HACNetwork.m
//  Pods
//
//  Created by macbook on 17/1/13.
//
//

#import "HACNetwork.h"
#import "AMUtils.h"
#import "HACHelp.h"
#import "HACWeakObject.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <sys/param.h>
#import <netinet/in.h>
#import <netinet/tcp.h>
#import <netinet/in_systm.h>
#import <netinet/ip.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <netdb.h>

#define NSNotifyCenter [NSNotificationCenter defaultCenter]
static NSString *kInterfaceWiFi = @"en0";
static NSString *kInterfaceWWAN = @"pdp_ip0";
static NSString *kInterfaceNone = @"";
NSString *const kHACNetworkStatusUpdated = @"kHACNetworkStatusUpdated";
NSString *const kHACNetworkExternalIPAddressUpdated = @"kHACNetworkExternalIPAddressUpdated";
@implementation HACNetwork {
    HACNetworkInfo *networkInfo;
    SCNetworkReachabilityRef reachability;
    NSString *currentInterface;
    CTTelephonyNetworkInfo *telephonyNetworkInfo;
    
    NSTimer *timer;
    void(^monitorBlock)(HACNetworkFlow *);
    BOOL isFirst;
    HACNetworkFlow *firstFlow;
}

- (void)dealloc {
    [self stop];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (reachability) {
        CFRelease(reachability);
    }
}

- (instancetype)init {
    if (self = [super init]) {
        isFirst = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentRadioTechnologyChangedCB) name:CTRadioAccessTechnologyDidChangeNotification object:nil];
    }
    return self;
}

- (HACNetworkInfo*)getNetworkInfo {
    networkInfo = [self populateNetworkInfo];
    return networkInfo;
}

+ (HACNetworkFlow*)getNetworkFlow {
    HACNetworkFlow *networkFlow;
    struct ifaddrs *ifa_list = 0, *ifa;
    
    if (getifaddrs(&ifa_list) == -1)
    {
        return nil;
    }
    
    uint32_t iBytes     = 0;
    uint32_t oBytes     = 0;
    uint32_t allFlow    = 0;
    uint32_t wifiIBytes = 0;
    uint32_t wifiOBytes = 0;
    uint32_t wifiFlow   = 0;
    uint32_t wwanIBytes = 0;
    uint32_t wwanOBytes = 0;
    uint32_t wwanFlow   = 0;
    struct IF_DATA_TIMEVAL time;
    
    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next)
    {
        if (AF_LINK != ifa->ifa_addr->sa_family)
            continue;
        
        if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING))
            continue;
        
        if (ifa->ifa_data == 0)
            continue;
        
        // Not a loopback device.
        // network flow
        if (strncmp(ifa->ifa_name, "lo", 2))
        {
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            
            iBytes += if_data->ifi_ibytes;
            oBytes += if_data->ifi_obytes;
            allFlow = iBytes + oBytes;
        }
        
        //wifi flow
        if (!strcmp(ifa->ifa_name, "en0"))
        {
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            
            wifiIBytes += if_data->ifi_ibytes;
            wifiOBytes += if_data->ifi_obytes;
            wifiFlow    = wifiIBytes + wifiOBytes;
            time = if_data->ifi_lastchange;
        }
        
        //3G and gprs flow
        if (!strcmp(ifa->ifa_name, "pdp_ip0"))
        {
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            
            wwanIBytes += if_data->ifi_ibytes;
            wwanOBytes += if_data->ifi_obytes;
            wwanFlow    = wwanIBytes + wwanOBytes;
        }
    }
    freeifaddrs(ifa_list);
    
    networkFlow = [[HACNetworkFlow alloc] init];
    networkFlow.allFlow = allFlow;
    networkFlow.inBytes = iBytes;
    networkFlow.outBytes = oBytes;
    networkFlow.wifiFlow = wifiFlow;
    networkFlow.wifiInBytes = wifiIBytes;
    networkFlow.wifiOutBytes = wifiOBytes;
    networkFlow.wwanFlow = wwanFlow;
    networkFlow.wwanInBytes = wwanIBytes;
    networkFlow.wwanOutBytes = wwanOBytes;
    networkFlow.lastChangeTime = time.tv_sec;
    
    return networkFlow;
}

// 持续监控
- (BOOL)isActive {
    return (timer != nil);
}

- (BOOL)startNetMonitorBlock:(void(^)(HACNetworkFlow *))block {
    if (block) {
        monitorBlock = [block copy];
        timer = [NSTimer scheduledTimerWithTimeInterval:1 target:[HACWeakObject weakObjectWithTarget:self] selector:@selector(timerFire) userInfo:nil repeats:YES];
    }
    return NO;
}

- (void)stop {
    [timer invalidate];
    timer = nil;
    isFirst = YES;
}

- (void)timerFire {
    HACNetworkFlow *networkFlow = [HACNetwork getNetworkFlow];
    if (isFirst) {
        //第一次的历史数据不参与统计
        isFirst = NO;
        firstFlow = networkFlow;
    } else {
        networkFlow.allFlow -= firstFlow.allFlow;
        networkFlow.inBytes -= firstFlow.inBytes;
        networkFlow.outBytes -= firstFlow.outBytes;
        networkFlow.wifiFlow -= firstFlow.wifiFlow;
        networkFlow.wifiInBytes -= firstFlow.wifiInBytes;
        networkFlow.wifiOutBytes -= firstFlow.wifiOutBytes;
        networkFlow.wwanFlow -= firstFlow.wwanFlow;
        networkFlow.wwanInBytes -= firstFlow.wwanInBytes;
        networkFlow.wwanOutBytes -= firstFlow.wwanOutBytes;
        monitorBlock(networkFlow);
    }
}

#pragma mark - private
- (HACNetworkInfo*)populateNetworkInfo
{
    if (HACObjectIsNull(networkInfo)) {
        networkInfo = [[HACNetworkInfo alloc] init];
    }
    currentInterface = [self internetInterface];
    HACBackground(^{
        networkInfo.externalIPAddress = @"-"; // Placeholder while fetching.
        networkInfo.externalIPAddress = [self getExternalIPAddress];
        HACMain(^{
            [NSNotifyCenter postNotificationName:kHACNetworkStatusUpdated object:nil];
        });
    });
    
    networkInfo.readableInterface = [self readableCurrentInterface];
    networkInfo.internalIPAddress = [self getInternalIPAddressOfInterface:currentInterface];
    networkInfo.netmask = [self getNetmaskOfInterface:currentInterface];
    networkInfo.broadcastAddress = [self getBroadcastAddressOfInterface:currentInterface];
    return networkInfo;
}

- (NSString*)internetInterface
{
    if (!reachability)
    {
        [self initReachability];
    }
    
    if (!reachability)
    {
        NSLog(@"cannot initialize reachability.");
        return kInterfaceNone;
    }
    
    SCNetworkReachabilityFlags flags;
    if (!SCNetworkReachabilityGetFlags(reachability, &flags))
    {
        NSLog(@"failed to retrieve reachability flags.");
        return kInterfaceNone;
    }
    
    if ((flags & kSCNetworkFlagsReachable) &&
        (!(flags & kSCNetworkReachabilityFlagsIsWWAN)))
    {
        return kInterfaceWiFi;
    }
    
    if ((flags & kSCNetworkReachabilityFlagsReachable) &&
        (flags & kSCNetworkReachabilityFlagsIsWWAN))
    {
        return kInterfaceWWAN;
    }
    
    return kInterfaceNone;
}

static void reachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
    assert(info != NULL);
    assert([(__bridge NSObject*)(info) isKindOfClass:[HACNetwork class]]);
    
    HACNetwork *networkCtrl = (__bridge HACNetwork*)(info);
    [networkCtrl reachabilityStatusChangedCB];
}

- (void)reachabilityStatusChangedCB {
    [self populateNetworkInfo];
    [NSNotifyCenter postNotificationName:kHACNetworkStatusUpdated object:nil];
}

- (void)initReachability
{
    if (!reachability)
    {
        struct sockaddr_in hostAddress;
        bzero(&hostAddress, sizeof(hostAddress));
        hostAddress.sin_len = sizeof(hostAddress);
        hostAddress.sin_family = AF_INET;
        
        reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&hostAddress);
        
        if (!reachability)
        {
            NSLog(@"reachability create has failed.");
            return;
        }
        
        BOOL result;
        SCNetworkReachabilityContext context = { 0, (__bridge void *)self, NULL, NULL, NULL };
        
        result = SCNetworkReachabilitySetCallback(reachability, reachabilityCallback, &context);
        if (!result)
        {
            NSLog(@"error setting reachability callback.");
            return;
        }
        
        result = SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        if (!result)
        {
            NSLog(@"error setting runloop mode.");
            return;
        }
    }
}

- (NSString*)getExternalIPAddress
{
    NSString *ip = @"-";
    
    if (![self internetConnected])
    {
        return ip;
    }
    
    NSURL *url = [NSURL URLWithString:@"http://ip.taobao.com/service/getIpInfo.php?ip=myip"];
    if (!url)
    {
        NSLog(@"failed to create NSURL.");
        return ip;
    }
    
    NSError *error = nil;
    NSString *ipHtml = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if (error)
    {
        NSLog(@"failed to fetch IP content: %@", error.description);
        return ip;
    }
    
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"([0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3})"
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:&error];
    if (error)
    {
        NSLog(@"failed to create regexp: %@", error.description);
        return ip;
    }
    NSRange regexpRange = [regexp rangeOfFirstMatchInString:ipHtml options:NSMatchingReportCompletion range:NSMakeRange(0, ipHtml.length)];
    NSString *match = [ipHtml substringWithRange:regexpRange];
    
    if (match && match.length > 0)
    {
        ip = [NSString stringWithString:match];
    }
    
    return ip;
}

- (BOOL)internetConnected
{
    if (!reachability)
    {
        [self initReachability];
    }
    
    if (!reachability)
    {
        NSLog(@"cannot initialize reachability.");
        return NO;
    }
    
    SCNetworkReachabilityFlags flags;
    if (!SCNetworkReachabilityGetFlags(reachability, &flags))
    {
        NSLog(@"failed to retrieve reachability flags.");
        return NO;
    }
    
    BOOL isReachable = (flags & kSCNetworkReachabilityFlagsReachable);
    BOOL noConnectionRequired = !(flags & kSCNetworkReachabilityFlagsConnectionRequired);
    
    if (flags & kSCNetworkReachabilityFlagsIsWWAN)
    {
        noConnectionRequired = YES;
    }
    
    return ((isReachable && noConnectionRequired) ? YES : NO);
}

- (NSString*)readableCurrentInterface
{
    if ([currentInterface isEqualToString:kInterfaceWiFi])
    {
        return @"WiFi";
    }
    else if ([currentInterface isEqualToString:kInterfaceWWAN])
    {
        static NSString *interfaceFormat = @"Cellular (%@)";
        if (HACObjectIsNull(telephonyNetworkInfo)) {
            telephonyNetworkInfo = [CTTelephonyNetworkInfo new];
        }
        NSString *currentRadioTechnology = [telephonyNetworkInfo currentRadioAccessTechnology];
        
        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyLTE])            return [NSString stringWithFormat:interfaceFormat, @"LTE"];
        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyEdge])           return [NSString stringWithFormat:interfaceFormat, @"Edge"];
        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyGPRS])           return [NSString stringWithFormat:interfaceFormat, @"GPRS"];
        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyCDMA1x] ||
            [currentRadioTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0] ||
            [currentRadioTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA] ||
            [currentRadioTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB])   return [NSString stringWithFormat:interfaceFormat, @"CDMA"];
        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyWCDMA])          return [NSString stringWithFormat:interfaceFormat, @"W-CDMA"];
        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyeHRPD])          return [NSString stringWithFormat:interfaceFormat, @"eHRPD"];
        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyHSDPA])          return [NSString stringWithFormat:interfaceFormat, @"HSDPA"];
        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyHSUPA])          return [NSString stringWithFormat:interfaceFormat, @"HSUPA"];
        
        // If technology is not known, keep it generic.
        return @"Cellular";
    }
    else
    {
        return @"Not Connected";
    }
}

- (NSString*)getInternalIPAddressOfInterface:(NSString*)interface
{
    NSString *address = @"-";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    
    if (!interface || interface.length == 0)
    {
        return address;
    }
    
    if (getifaddrs(&interfaces) == 0)
    {
        temp_addr = interfaces;
        
        while (temp_addr != NULL)
        {
            if (temp_addr->ifa_addr->sa_family == AF_INET)//TO-DO: ipv6
            {
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:interface])
                {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in*)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    return address;
}

- (NSString*)getNetmaskOfInterface:(NSString*)interface
{
    NSString *netmask = @"-";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    
    if (!interface || interface.length == 0)
    {
        return netmask;
    }
    
    if (getifaddrs(&interfaces) == 0)
    {
        temp_addr = interfaces;
        
        while (temp_addr != NULL)
        {
            if (temp_addr->ifa_addr->sa_family == AF_INET)//TO-DO: ipv6
            {
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:interface])
                {
                    netmask = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in*)temp_addr->ifa_netmask)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    return netmask;
}

- (NSString*)getBroadcastAddressOfInterface:(NSString*)interface
{
    NSString *address = @"-";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    
    if (!interface || interface.length == 0)
    {
        return address;
    }
    
    if (getifaddrs(&interfaces) == 0)
    {
        temp_addr = interfaces;
        
        while (temp_addr != NULL)
        {
            if (temp_addr->ifa_addr->sa_family == AF_INET)
            {
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:interface])
                {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in*)temp_addr->ifa_dstaddr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    return address;
}

- (void)currentRadioTechnologyChangedCB
{
    [self populateNetworkInfo];
    [NSNotifyCenter postNotificationName:kHACNetworkStatusUpdated object:nil];
}
@end
