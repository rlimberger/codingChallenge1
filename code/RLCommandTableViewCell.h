//
//  RLCommandTableViewCell.h
//
//  Created by rl on 3/26/14.
//  Copyright (c) 2014 Rene Limberger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RLSwatchView.h"

/**
 `RLCommandTableViewCell` is the base class for all the different table view cells that represent the different
 command types.
 */
@interface RLCommandTableViewCell : UITableViewCell

@property (strong) IBOutlet UILabel* commandValueLabel;

@end

/**
 `RLAbsoluteCommandTableViewCell` implements the visual appearance of an absolute command.
 */
@interface RLAbsoluteCommandTableViewCell : RLCommandTableViewCell

@property (strong) IBOutlet RLSwatchView* colorSwatchView;

@end

/**
 `RLAbsoluteCommandTableViewCell` implements the visual appearance of an relative command.
 */
@interface RLRelativeCommandTableViewCell : RLCommandTableViewCell
@end


