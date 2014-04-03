//
//  RLCommandStack.h
//  codingChallenge
//
//  Created by rl on 4/2/14.
//  Copyright (c) 2014 Rene Limberger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RLCommand.h"

/**
 `RLCommandStack` is the data model.
 
 @discussion
 This model manages a stack of commands and a resulting current state.
 */
@interface RLCommandStackModel : NSObject

/**
 Singleton instance
 */
+ (RLCommandStackModel*)sharedCommandStackModel;

/**
 Initializes the command stack to a default state.
 */
- (void)initCommandStack;

/**
 Toggle the active state of a comand.
 
 @param
 Index of the comand to toggle.
 
 @return
 Returns Yes if the command was toggled.
 */
- (BOOL)toggleActive:(NSInteger)index;

/**
 Get the command at a given index.
 
 @param
 Index of the comand to retrieve. Will return nil if index is out of bounds.
 */
- (RLCommand*)commandAtIndex:(NSInteger)index;

/**
 Push a new command onto the stack.
 
 @param
 The new command to be pushed onto the stack.
 */
- (void)pushCommand:(RLCommand*)command;

/**
 Get the size of the current stack.
 */
- (NSInteger)stackSize;

/**
 Get the red color of the current state.
 */
- (NSInteger)currentR;

/**
 Get the green color of the current state.
 */
- (NSInteger)currentG;

/**
 Get the blue color of the current state.
 */
- (NSInteger)currentB;



@end
