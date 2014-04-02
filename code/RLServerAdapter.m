//
//  RLServerAdapter.m
//
//  Created by rl on 3/25/14.
//  Copyright (c) 2014 Rene Limberger. All rights reserved.
//

#import "RLServerAdapter.h"
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

- (id)init
{
    if((self = [super init])) {
        _commandStack = [NSMutableArray array];
    }
    return self;
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
    [self initCommandStack];
    
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
    [self pushCommand:command];
}

#pragma mark - stack

- (void)pushCommand:(RLCommand*)command
{
    // because we are going to add a new absolute command,
    // all previous commands should become inactive (deselected)
    // the new command added below will be active by default
    if(command.type == CommandTypeAbsolute) {
        for(RLCommand* c in self.commandStack)
            c.active = NO;
    }
    
    // FIXME: according to challenge, there is no conditon
    // where the command stack/log will be reset.
    // eventually, this will cause a memory problem, but we ignore this
    // for now
    [self.commandStack addObject:command];
    
    // state needs to be updated
    [self recomputeCurrentColorState];
    
    // send NSNotification so the controllers can update their UI
    [[NSNotificationCenter defaultCenter] postNotificationName:@"newCommand" object:command];
}

- (void)initCommandStack
{
    // according to the server spec, we should start with
    // these defaults in the stack
    unsigned char bytes[4] = {CommandTypeAbsolute, 127, 127, 127};
    NSData* data = [NSData dataWithBytes:(const void*)bytes length:4];
    RLCommand* command = [[RLCommand alloc] initWithData:data];
    [self.commandStack removeAllObjects];
    [self pushCommand:command];
}

#pragma mark - state

- (void)recomputeCurrentColorState
{
    // according to the server coding challenge, the processing
    // of the state may be CPU intensive in the future. so we
    // do this potentially "expensive" work on a dedicated queue
    dispatch_async([RLServerAdapter dispatchQueue], ^{
        RLCommand* currentAbsoluteCommand = nil;
        
        // walk stack from top to bottom to find the last absolute command
        for(RLCommand* command in self.commandStack.reverseObjectEnumerator) {
            if(command.type == CommandTypeAbsolute) {
                currentAbsoluteCommand = command;
                break;
            }
        }
        
        // failsafe, we should never end up in this condition since we init the stack with
        // an absolute command, but just to be safe
        if(!currentAbsoluteCommand)
            return;
        
        // now walk up the stack from the current absolute command and apply all active
        // change commands
        _currentR = currentAbsoluteCommand.r;
        _currentG = currentAbsoluteCommand.g;
        _currentB = currentAbsoluteCommand.b;
        NSInteger indexOfCurrentAbsoluteCommand = [self.commandStack indexOfObject:currentAbsoluteCommand];
        for(NSInteger i = indexOfCurrentAbsoluteCommand; i < self.commandStack.count; i++) {
            RLCommand* command = self.commandStack[i];
            
            // we should not encounter any absolute commands at this point, but
            // lets just make sure
            if(command.type == CommandTypeRelative && command.active) {
                _currentR = (_currentR + command.r) % 255;
                _currentG = (_currentG + command.g) % 255;
                _currentB = (_currentB + command.b) % 255;
            }
        }
        
        // send NSNotification so the controllers can update their UI
        [[NSNotificationCenter defaultCenter] postNotificationName:@"currentStateUpdated" object:nil];
    });
}

// singleton background queue
+ (dispatch_queue_t)dispatchQueue
{
    static dispatch_queue_t __adapterDispatchQueue = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __adapterDispatchQueue = dispatch_queue_create("com.rl.codingchallenge.adapterDispatchQueue", NULL);
    });
    return __adapterDispatchQueue;
}


@end
