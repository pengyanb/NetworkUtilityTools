//
//  ReverseDns.h
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 31/12/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <netdb.h>
#include <errno.h>
#include <AssertMacros.h>
#include <arpa/inet.h>

@interface ReverseDns : NSObject 
+(void) startResolveDomainName:(NSString*)ipv4Address withCompleteHandler: (void (^)(NSString *))handler;
@end
