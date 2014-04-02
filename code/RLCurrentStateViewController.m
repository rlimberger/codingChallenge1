//
//  RLCurrentStateViewController.m
//
//  Created by rl on 3/26/14.
//  Copyright (c) 2014 Rene Limberger. All rights reserved.
//

#import "RLCurrentStateViewController.h"
#import "RLServerAdapter.h"

#pragma mark - private interface

@interface RLCurrentStateViewController ()
{
    IBOutlet UIView* currentColorStateSwatch;
    IBOutlet UILabel* currentColorStateLabel;
}

@end

@implementation RLCurrentStateViewController

#pragma mark - Controller life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // sign up for state change notification
    __weak RLCurrentStateViewController* weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:@"currentStateUpdated" object:nil queue:nil usingBlock:^(NSNotification* note) {
        RLCurrentStateViewController* strongSelf = weakSelf;
        [strongSelf update];
    }];
    
    // make swatch pretty
    if(currentColorStateSwatch) {
        currentColorStateSwatch.layer.borderWidth = 1;
        currentColorStateSwatch.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
        currentColorStateSwatch.layer.cornerRadius = 5;
    }
    
    // set initial state of lable and swatch
    [self update];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UI update

- (void)update
{
    // this function may be called from any thread (i.e. a notification), so we need
    // to make sure we run the UI update on the main thread
    dispatch_async(dispatch_get_main_queue(), ^(void){
        currentColorStateSwatch.backgroundColor = [UIColor colorWithRed:[RLServerAdapter sharedAdapter].currentR/255.0f green:[RLServerAdapter sharedAdapter].currentG/255.0f blue:[RLServerAdapter sharedAdapter].currentB/255.0f alpha:1.0f];
        currentColorStateLabel.text = [NSString stringWithFormat:@"R:%ld G:%ld B:%ld", (long)[RLServerAdapter sharedAdapter].currentR, (long)[RLServerAdapter sharedAdapter].currentG, (long)[RLServerAdapter sharedAdapter].currentB];
    });
}

@end
