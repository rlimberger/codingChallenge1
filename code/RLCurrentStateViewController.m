//
//  RLCurrentStateViewController.m
//
//  Created by rl on 3/26/14.
//  Copyright (c) 2014 Rene Limberger. All rights reserved.
//

#import "RLCurrentStateViewController.h"
#import "RLCommandStackModel.h"
#import "RLSwatchView.h"

#pragma mark - private interface

@interface RLCurrentStateViewController ()
{
    IBOutlet RLSwatchView* currentColorStateSwatch;
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
    
    // set initial state of lable and swatch
    [self update];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    // unsubscribe from the notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UI update

- (void)update
{
    // get current values
    RLCommandStackModel* commandStackModel = [RLCommandStackModel sharedCommandStackModel];
    NSUInteger r = commandStackModel.currentR;
    NSUInteger g = commandStackModel.currentG;
    NSUInteger b = commandStackModel.currentB;
    UIColor* c = [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f];
    NSString* s = [NSString stringWithFormat:@"R:%ld G:%ld B:%ld", (long)r, (long)g, (long)b];
    
    // this function may be called from any thread (i.e. a notification), so we need
    // to make sure we run the UI update on the main thread
    __weak RLCurrentStateViewController* weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^(void){
        RLCurrentStateViewController* strongSelf = weakSelf;
        [strongSelf->currentColorStateSwatch setColor:c];
        strongSelf->currentColorStateLabel.text = s;
    });
}

@end














