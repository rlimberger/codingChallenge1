//
//  RLCommandTableViewCell.m
//
//  Created by rl on 3/26/14.
//  Copyright (c) 2014 Rene Limberger. All rights reserved.
//

#import "RLCommandTableViewCell.h"

#pragma mark - private RLCommandTableViewCell

@implementation RLCommandTableViewCell

@end

#pragma mark - private RLAbsoluteCommandTableViewCell

@implementation RLAbsoluteCommandTableViewCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // make the color swatch pretty
    if(self.colorSwatchView) {
        self.colorSwatchView.layer.borderWidth = 1;
        self.colorSwatchView.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
        self.colorSwatchView.layer.cornerRadius = 5;
    }
}

@end

#pragma mark - private RLRelativeCommandTableViewCell

@implementation RLRelativeCommandTableViewCell

@end