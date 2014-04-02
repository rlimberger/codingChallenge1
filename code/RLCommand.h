//
//  RLCommand.h
//
//  Created by rl on 3/25/14.
//  Copyright (c) 2014 Rene Limberger. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 `RLCommandType` is as custom type to be able to identify different kinds of commands sent by the server. This type is used in the `<RLCommand>` .type property;
 */
typedef enum _commandTypes
{
    CommandTypeInvalid  = 0x00,
    CommandTypeRelative,
    CommandTypeAbsolute,
    NUM_CommandTypes
} RLCommandType;


/**
 `RLCommand` is an object that encapsulates a command as sent by the server.
 */
@interface RLCommand : NSObject

/**
 Type of the command
 
 @discussion 
 The server sends different kinds of commands. This porperty can be used to identify the different kinds. See `<RLCommandType>` for the differnt types possible.
 */
@property (readonly) RLCommandType type;

/**
 The value of the red component of the command.
 
 @discussion 
 The meaning of this value depends on the `<RLCommandType>` of the command.
 */
@property (readonly) NSInteger r;

/**
 The value of the green component of the command.
 
 @discussion 
 The meaning of this value depends on the `<RLCommandType>` of the command.
 */
@property (readonly) NSInteger g;

/**
 The value of the blue component of the command.
 
 @discussion 
 The meaning of this value depends on the `<RLCommandType>` of the command.
 */
@property (readonly) NSInteger b;

/**
 The state of the command.
 
 @discussion 
 A command can be active or inactive. An inactive command is not considered in the computation of the state.
 */
@property (readwrite) BOOL active;

/**
 Initializes a command instance.
 
 @param 
 data The raw data as received from the server.
 */
- (id)initWithData:(NSData*)data;

@end
