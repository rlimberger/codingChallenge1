//
//  RLServerAdapter.h
//
//  Created by rl on 3/25/14.
//  Copyright (c) 2014 Rene Limberger. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 `RLServerAdapter` is the Model of data for the the server coding challenge. 
 
 @discussion 
 It handles communication with the
  server and keeps a stack of coomands. It also handles the computation of the current state.
 */
@interface RLServerAdapter : NSObject

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

@end
