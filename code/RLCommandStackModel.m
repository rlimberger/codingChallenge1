//
//  RLCommandStack.m
//  codingChallenge
//
//  Created by rl on 4/2/14.
//  Copyright (c) 2014 Rene Limberger. All rights reserved.
//

#import "RLCommandStackModel.h"

@interface RLCommandStackModel ()
{
    NSMutableArray* commandStack;
    UIColor* stateColor;
    NSInteger currentStateR;
    NSInteger currentStateG;
    NSInteger currentStateB;
}

@end

@implementation RLCommandStackModel

+ (RLCommandStackModel*)sharedCommandStackModel
{
    static RLCommandStackModel* singleton = nil;
    static dispatch_once_t done;
    
    dispatch_once(&done, ^
                  {
                      singleton = [RLCommandStackModel new];
                  });
    
    return singleton;
}

- (id)init
{
    if((self = [super init])) {
        commandStack = [NSMutableArray array];
        stateColor = [UIColor blackColor];
        currentStateR = 0;
        currentStateG = 0;
        currentStateB = 0;
    }
    return self;
}


#pragma mark - stack

- (void)pushCommand:(RLCommand*)command
{
    __weak RLCommandStackModel* weakSelf = self;
    dispatch_async([RLCommandStackModel dispatchQueue], ^{
        RLCommandStackModel* strongSelf = weakSelf;
        
        // because we are going to add a new absolute command,
        // all previous commands should become inactive (deselected)
        // the new command added below will be active by default
        if(command.type == CommandTypeAbsolute) {
            for(RLCommand* c in strongSelf->commandStack)
                c.active = NO;
        }
        
        // FIXME: according to challenge, there is no conditon
        // where the command stack/log will be reset.
        // eventually, this will cause a memory problem, but we ignore this
        // for now
        [strongSelf->commandStack addObject:command];
        
        // state needs to be updated
        [strongSelf recomputeCurrentColorState];
        
        // send NSNotification so the controllers can update their UI
        [[NSNotificationCenter defaultCenter] postNotificationName:@"newCommand" object:command];
    });
}

- (void)initCommandStack
{
    __weak RLCommandStackModel* weakSelf = self;
    dispatch_async([RLCommandStackModel dispatchQueue], ^{
        RLCommandStackModel* strongSelf = weakSelf;
        
        // according to the server spec, we should start with
        // these defaults in the stack
        unsigned char bytes[4] = {CommandTypeAbsolute, 127, 127, 127};
        NSData* data = [NSData dataWithBytes:(const void*)bytes length:4];
        RLCommand* command = [[RLCommand alloc] initWithData:data];
        
        [strongSelf->commandStack removeAllObjects];
        [strongSelf pushCommand:command];
        [strongSelf recomputeCurrentColorState];
        
        // send NSNotification so the controllers can update their UI
        dispatch_async([RLCommandStackModel notificationQueue], ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"newCommand" object:command];
        });
    });
}

#pragma mark - state

- (void)recomputeCurrentColorState
{
    // according to the server coding challenge, the processing
    // of the state may be CPU intensive in the future. so we
    // do this potentially "expensive" work on a dedicated queue
    __weak RLCommandStackModel* weakSelf = self;
    dispatch_async([RLCommandStackModel dispatchQueue], ^{
        RLCommandStackModel* strongSelf = weakSelf;
        
        RLCommand* currentAbsoluteCommand = nil;
        // walk stack from top to bottom to find the last absolute command
        for(RLCommand* command in strongSelf->commandStack.reverseObjectEnumerator) {
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
        strongSelf->currentStateR = currentAbsoluteCommand.r;
        strongSelf->currentStateG = currentAbsoluteCommand.g;
        strongSelf->currentStateB = currentAbsoluteCommand.b;
        NSInteger indexOfCurrentAbsoluteCommand = [strongSelf->commandStack indexOfObject:currentAbsoluteCommand];
        for(NSInteger i = indexOfCurrentAbsoluteCommand; i < strongSelf->commandStack.count; i++) {
            RLCommand* command = strongSelf->commandStack[i];
            
            // we should not encounter any absolute commands at this point, but
            // lets just make sure
            if(command.type == CommandTypeRelative && command.active) {
                strongSelf->currentStateR = (strongSelf->currentStateR + command.r) % 255;
                strongSelf->currentStateG = (strongSelf->currentStateG + command.g) % 255;
                strongSelf->currentStateB = (strongSelf->currentStateB + command.b) % 255;
            }
        }
        
        // send NSNotification so the controllers can update their UI
        dispatch_async([RLCommandStackModel notificationQueue], ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"currentStateUpdated" object:nil];
        });
    });
}

- (BOOL)toggleActive:(NSInteger)index
{
    if(index < 0 || index >= commandStack.count)
        return NO;
    
    __weak RLCommandStackModel* weakSelf = self;
    __block BOOL toggled = NO;
    dispatch_sync([RLCommandStackModel dispatchQueue], ^{
        RLCommandStackModel* strongSelf = weakSelf;
        RLCommand* command = [strongSelf->commandStack objectAtIndex:strongSelf->commandStack.count-1-index];
        
        if(command) {
            command.active = !command.active;
            [strongSelf recomputeCurrentColorState];
            toggled = YES;
        }
    });
    
    return toggled;
}

- (RLCommand*)commandAtIndex:(NSInteger)index
{
    if(index < 0 || index >= commandStack.count)
        return nil;
    
    __block RLCommand* command = nil;
    __weak RLCommandStackModel* weakSelf = self;
    dispatch_sync([RLCommandStackModel dispatchQueue], ^{
        RLCommandStackModel* strongSelf = weakSelf;
        command = [strongSelf->commandStack objectAtIndex:strongSelf->commandStack.count-1-index];
    });
    
    return command;
}

- (NSInteger)stackSize
{
    __block NSInteger stackSize = 0;
    __weak RLCommandStackModel* weakSelf = self;
    dispatch_sync([RLCommandStackModel dispatchQueue], ^{
        RLCommandStackModel* strongSelf = weakSelf;
        stackSize = strongSelf->commandStack.count;
    });
    
    return stackSize;
}

- (NSInteger)currentR
{
    __block NSInteger r = 0;
    __weak RLCommandStackModel* weakSelf = self;
    dispatch_sync([RLCommandStackModel dispatchQueue], ^{
        RLCommandStackModel* strongSelf = weakSelf;
        r = strongSelf->currentStateR;
    });
    
    return r;
}

- (NSInteger)currentG
{
    __block NSInteger g = 0;
    __weak RLCommandStackModel* weakSelf = self;
    dispatch_sync([RLCommandStackModel dispatchQueue], ^{
        RLCommandStackModel* strongSelf = weakSelf;
        g = strongSelf->currentStateG;
    });
    
    return g;
}

- (NSInteger)currentB
{
    __block NSInteger b = 0;
    __weak RLCommandStackModel* weakSelf = self;
    dispatch_sync([RLCommandStackModel dispatchQueue], ^{
        RLCommandStackModel* strongSelf = weakSelf;
        b = strongSelf->currentStateB;
    });
    
    return b;
}

// singleton background queue
+ (dispatch_queue_t)dispatchQueue
{
    static dispatch_queue_t adapterDispatchQueue = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapterDispatchQueue = dispatch_queue_create("com.rl.codingchallenge.commandStackModelDispatchQueue", NULL);
    });
    return adapterDispatchQueue;
}

// singleton notification queue
+ (dispatch_queue_t)notificationQueue
{
    static dispatch_queue_t adapterDispatchQueue = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapterDispatchQueue = dispatch_queue_create("com.rl.codingchallenge.commandStackModelNotificationQueue", NULL);
    });
    return adapterDispatchQueue;
}


@end
