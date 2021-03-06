//
//  RLCommandLogTableViewController.m
//
//  Created by rl on 3/26/14.
//  Copyright (c) 2014 Rene Limberger. All rights reserved.
//

#import "RLCommandLogTableViewController.h"
#import "RLCommandStackModel.h"
#import "RLCommandTableViewCell.h"
#import "RLSwatchView.h"

#pragma mark - private interface

@interface RLCommandLogTableViewController ()
{
    IBOutlet RLSwatchView* currentColorSwatch;
}

@end

@implementation RLCommandLogTableViewController

#pragma mark - Controller life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // sign up for notifications whenever the stack or state change
    __weak RLCommandLogTableViewController* weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:@"newCommand" object:nil queue:nil usingBlock:^(NSNotification* note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            RLCommandLogTableViewController* strongSelf = weakSelf;
            [strongSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        });
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"currentStateUpdated" object:nil queue:nil usingBlock:^(NSNotification* note) {
        RLCommandLogTableViewController* strongSelf = weakSelf;
        [strongSelf updateCurrentStateSwatch];
    }];
    
    // set initial state of the color swtach in the navigation bar
    [self updateCurrentStateSwatch];
}

- (void)dealloc
{
    // unsubscribe from the notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // we have only 1 section in this demo
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [RLCommandStackModel sharedCommandStackModel].stackSize;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RLCommand* command = [[RLCommandStackModel sharedCommandStackModel] commandAtIndex:indexPath.row];
    if(!command)
        return nil;
    
    UITableViewCell* cell = nil;
    
    // deque and configure the correct cell type based on command type
    if(command.type == CommandTypeAbsolute) {
        static NSString* absoluteCellReuseIdentitier = @"AbsoluteCell";
        RLAbsoluteCommandTableViewCell* absoluteCell = [tableView dequeueReusableCellWithIdentifier:absoluteCellReuseIdentitier forIndexPath:indexPath];
        
        // build text
        absoluteCell.commandValueLabel.text = [NSString stringWithFormat:@"R=%ld G=%ld B=%ld", (long)command.r, (long)command.g, (long)command.b];
        
        // set color swatch
        [absoluteCell.colorSwatchView setColor:[UIColor colorWithRed:command.r/255.0f green:command.g/255.0f blue:command.b/255.0f alpha:1.0f]];
        
        // set accessory type based on active state of the command
        absoluteCell.accessoryType = (command.active) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
        cell = absoluteCell;
    }
    else if(command.type == CommandTypeRelative) {
        static NSString* relativeCellReuseIdentitier = @"RelativeCell";
        RLRelativeCommandTableViewCell* relativeCell = [tableView dequeueReusableCellWithIdentifier:relativeCellReuseIdentitier forIndexPath:indexPath];
        
        // build text
        relativeCell.commandValueLabel.text = [NSString stringWithFormat:@"R+%ld G+%ld B+%ld", (long)command.r, (long)command.g, (long)command.b];
        
        // set accessory type based on active state of the command
        relativeCell.accessoryType = (command.active) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
        cell = relativeCell;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // figure out which command this row represents
    BOOL toggled = [[RLCommandStackModel sharedCommandStackModel] toggleActive:indexPath.row];
    
    if(toggled) {
        // rebuild this row
        [tableView beginUpdates];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView endUpdates];
    }
    
    // we are done with this row now, as it has it's accessort type updated by now
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UI update

- (void)updateCurrentStateSwatch
{
    // get current values
    RLCommandStackModel* commandStackModel = [RLCommandStackModel sharedCommandStackModel];
    NSUInteger r = commandStackModel.currentR;
    NSUInteger g = commandStackModel.currentG;
    NSUInteger b = commandStackModel.currentB;
    UIColor* c = [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f];
    
    // this function may be called from any thread (i.e. a notification), so we need
    // to make sure we run the UI update on the main thread
    __weak RLCommandLogTableViewController* weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^(void){
        RLCommandLogTableViewController* strongSelf = weakSelf;
        [strongSelf->currentColorSwatch setColor:c];
    });
}

@end
