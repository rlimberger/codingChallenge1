//
//  RLServerAdapter.m
//
//  Created by rl on 3/25/14.
//  Copyright (c) 2014 Rene Limberger. All rights reserved.
//

#import "RLServerAdapter.h"
#import "RLCommandStackModel.h"
#import <netdb.h>

#define READ_BUFFER_SIZE 512

#pragma mark - Private class extension

@interface RLServerAdapter () <NSStreamDelegate, UIAlertViewDelegate>
{
    NSString* hostname;
    NSInteger port;
    dispatch_source_t source;
}

@end

#pragma mark

@implementation RLServerAdapter

+ (RLServerAdapter*)sharedAdapter
{
    static RLServerAdapter* singleton = nil;
    static dispatch_once_t done;
    
    dispatch_once(&done, ^
                  {
                      singleton = [RLServerAdapter new];
                  });
    
    return singleton;
}

#pragma mark - connection implementation

- (void)connectToServer:(NSString*)aHostname withPort:(NSInteger)aPort
{
    hostname = aHostname;
    port = aPort;
    
    // make sure we got valid input
    if(!hostname || !hostname.length || !port) {
        [self handleError];
        return;
    }
    
    // init our stack
    [[RLCommandStackModel sharedCommandStackModel] initCommandStack];
    
    // create socket connetion and event handlers
    __weak RLServerAdapter* weakSelf = self;
    dispatch_async([RLServerAdapter dispatchQueue], ^{
        RLServerAdapter* strongSelf = weakSelf;
        
        // fill data structures for socket calls
        struct addrinfo hints, *res;
        memset(&hints, 0, sizeof hints);
        hints.ai_family = AF_INET;
        hints.ai_socktype = SOCK_STREAM;
        getaddrinfo(strongSelf->hostname.UTF8String, [NSString stringWithFormat:@"%ld", (long)strongSelf->port].UTF8String, &hints, &res);
        
        // Create socket and connect
        int listenSocket = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
        connect(listenSocket, res->ai_addr, res->ai_addrlen);
        fcntl(listenSocket, F_SETFL, O_NONBLOCK);
        
        // Create dispatch source for socket
        strongSelf->source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, listenSocket, 0, [RLServerAdapter dispatchQueue]);
        
        // set bytes available handler
        dispatch_source_set_event_handler(strongSelf->source, ^{
            char buf[READ_BUFFER_SIZE];
            ssize_t numBytesRead;
            numBytesRead = read(listenSocket, buf, READ_BUFFER_SIZE-1);
            if(numBytesRead) {
                NSData* data = [NSData dataWithBytes:buf length:numBytesRead];
                [strongSelf processData:data];
            }
        });
        
        // set cancel handler (socket might get closed by server)
        dispatch_source_set_cancel_handler(strongSelf->source, ^{
            close(listenSocket);
            dispatch_suspend(strongSelf->source);
        });
        
        // start the source
        dispatch_resume(strongSelf->source);
    });
}

- (void)handleError
{
    // post alert view, giving the user the option to retry
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Connection failed!"
                                                    message:[NSString stringWithFormat:@"Connection to %@:%ld failed. Try again?", hostname, (long)port]
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Retry", nil];
    [alert show];
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // if the retry button was clicked, connect again
    if(buttonIndex)
        [self connectToServer:hostname withPort:port];
}

#pragma mark - data processing

- (void)processData:(NSData*)data
{
    if(!data || !data.length)
        return;
    
    // turn raw bytes into command object
    RLCommand* command = [[RLCommand alloc] initWithData:data];
    if(!command)
        return;
    
    // add new command to stack
    [[RLCommandStackModel sharedCommandStackModel] pushCommand:command];
}

#pragma mark - queues

// singleton background queue
+ (dispatch_queue_t)dispatchQueue
{
    static dispatch_queue_t adapterDispatchQueue = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapterDispatchQueue = dispatch_queue_create("com.rl.codingchallenge.adapterDispatchQueue", NULL);
    });
    return adapterDispatchQueue;
}


@end
