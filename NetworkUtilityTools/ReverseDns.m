//
//  ReverseDns.m
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 31/12/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

#include "ReverseDns.h"

@interface ReverseDns()

@end

@implementation ReverseDns

+ (void) startResolveDomainName:(NSString*)ipv4Address withCompleteHandler:(void (^)(NSString *))handler {
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        struct sockaddr_in sa_in;
        char host[NI_MAXHOST], service[NI_MAXSERV];
        int flags;
        int err;
        
        sa_in.sin_family = AF_INET;
        sa_in.sin_port = htons(80);
        inet_pton(AF_INET, [ipv4Address UTF8String], &sa_in.sin_addr.s_addr);
        flags = 0; // NI_NUMERICHOST | NI_NUMERICSERV
        err = getnameinfo((struct sockaddr *)(&sa_in), sizeof(struct sockaddr), host, sizeof(host), service, sizeof(service), flags);
        
        if(err == 0){
            handler([NSString stringWithUTF8String:host]);
        }
        else{
            handler(ipv4Address);
        }
        
    });
}
@end










































