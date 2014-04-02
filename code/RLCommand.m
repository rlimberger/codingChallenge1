//
//  RLCommand.m
//
//  Created by rl on 3/25/14.
//  Copyright (c) 2014 Rene Limberger. All rights reserved.
//

#import "RLCommand.h"

@implementation RLCommand

// The server code specifically sends big endian
//
// swap bytes to convert to little endian
// (both simulator/intel and device/arm are little endian)
//
// FIXME: CFSwapInt16BigToHost should work here. not sure
// why we didn't get the right result. Revist when time.
signed short swap(signed short x)
{
    return x << 8 | x >> 8;
}

- (id)initWithData:(NSData*)data
{
    if((self = [super init])) {
        if(data && data.length) {
            
            // figure out message type
            unsigned char* bytes = (unsigned char*)data.bytes;
            _type = bytes[0];
            
            switch(_type)
            {
                case CommandTypeAbsolute:
                {
                    if(data.length == 4) {
                        unsigned char* ucharBytes = bytes+1;
                        
                        // these are just single bytes, no need to swap, see comments above
                        _r = ucharBytes[0];
                        _g = ucharBytes[1];
                        _b = ucharBytes[2];
                    }
                    break;
                }
                    
                case CommandTypeRelative:
                {
                    if(data.length == 7) {
                        // cast to signed short, as this is what the server sends for this message type
                        signed short* intBytes = (signed short*)(bytes+1);
                        
                        // need to change endianess, see comments on swap function
                        _r = swap(intBytes[0]);
                        _g = swap(intBytes[1]);
                        _b = swap(intBytes[2]);
                    }
                    break;
                }
                    
                default:
                    // TODO: should assrt invalid command types
                    break;
            }
            
            // new command is active by default
            _active = YES;
        }
    }
    return self;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"type:%ld r:%ld g:%ld b:%ld active:%ld", (long)self.type, (long)self.r, (long)self.g, (long)self.b, (long)self.active];
}

@end
