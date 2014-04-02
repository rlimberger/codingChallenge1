//
//  RLServerAdapter.h
//
//  Created by rl on 3/25/14.
//  Copyright (c) 2014 Rene Limberger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RLCommand.h"

/**
 `RLServerAdapter` is the Model of data for the the server coding challenge. 
 
 @discussion 
 It handles communication with the
  server and keeps a stack of coomands. It also handles the computation of the current state.
 */
@interface RLServerAdapter : NSObject

/**
 Current Red value of the state.
 
 @discussion 
 Whenever the command stack grows or the active state of commands changes, this model will
 recompute the state.
 */
@property (readonly) NSUInteger currentR;

/**
 Current Green value of the state.
 
 @discussion 
 Whenever the command stack grows or the active state of commands changes, this model will
 recompute the state.
 */
@property (readonly) NSUInteger currentG;

/**
 Current Blue value of the state.
 
 @discussion 
 Whenever the command stack grows or the active state of commands changes, this model will
 recompute the state.
 */
@property (readonly) NSUInteger currentB;

/**
 Singleton instance
 */
+ (RLServerAdapter*)sharedAdapter;

/**
 Connects this model to a server.
 
 @param 
 aHostname The name of the server to connect to.
 
 @param 
 aPort The port number of the server to connect to.
 */
- (void)connectToServer:(NSString*)aHostname withPort:(NSInteger)aPort;

/**
 Toggle the active state of a comand.
 
 @param
 Index of the comand to toggle.
 
 @return
 Yes if the command was toggled.
 */
- (BOOL)toggleActive:(NSInteger)index;

/**
 Get the command at a given index.
 
 @param
 Index of the comand to retrieve. Will return nil if index is out of bounds.
 */
- (RLCommand*)commandAtIndex:(NSInteger)index;

/**
 Get the size of the current stack.
 */
- (NSInteger)stackSize;

@end
