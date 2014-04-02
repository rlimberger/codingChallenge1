//
//  RLSwatchView.h
//  codingChallenge
//
//  Created by rl on 4/2/14.
//  Copyright (c) 2014 Rene Limberger. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 `RLSwatchView` is a simple view that draws itself as a rounded rect.
 
 @discussion
 The common (and much simpler) way to make a UIView have rounded corners is to use 
 the view's CALayer property and it's corner properties.
 
 The problem with this is that it uses a bitmap as backing store and depending on the
 size of the view, maye use a lot of memory. If the layer's properties are set only at init
 or rather infrequently, this isn't a big deal but changing it frequently will lead to
 a lot of virtual being marked dirty. 
 
 Sp we choose to implement the color change with a traditional drawRect.
 */
@interface RLSwatchView : UIView

/**
 Set the color of the view.
 
 @param 
 aColor The new color of the view.
 
 @discussion
 This methods will cause a redraw.
 */
- (void)setColor:(UIColor*)aColor;

@end
