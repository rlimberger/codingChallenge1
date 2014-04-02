//
//  RLCommandLogTableViewController.m
//
//  Created by rl on 3/26/14.
//  Copyright (c) 2014 Rene Limberger. All rights reserved.
//

#import "RLCommandLogTableViewController.h"
#import "RLServerAdapter.h"
#import "RLCommandTableViewCell.h"

#pragma mark - private interface

@interface RLCommandLogTableViewController ()
{
    IBOutlet UIView* currentColorSwatch;
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
            [strongSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"currentStateUpdated" object:nil queue:nil usingBlock:^(NSNotification* note) {
        RLCommandLogTableViewController* strongSelf = weakSelf;
        [strongSelf updateCurrentStateSwatch];
    }];
    
    // make the color swatch in the navigation bar pretty
    if(currentColorSwatch) {
        currentColorSwatch.layer.borderWidth = 1;
        currentColorSwatch.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
        currentColorSwatch.layer.cornerRadius = 3;
    }
    
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
    // command stack size determines row count
    return [RLServerAdapter sharedAdapter].commandStack.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // make sure this row has a command
    if(indexPath.row >= [RLServerAdapter sharedAdapter].commandStack.count)
        return nil;
    
    // get the command for this row
    RLCommand* command = (RLCommand*)[RLServerAdapter sharedAdapter].commandStack[[RLServerAdapter sharedAdapter].commandStack.count-1-indexPath.row];
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
        absoluteCell.colorSwatchView.backgroundColor = [UIColor colorWithRed:command.r/255.0f green:command.g/255.0f blue:command.b/255.0f alpha:1.0f];
        
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
    RLCommand* command = (RLCommand*)[RLServerAdapter sharedAdapter].commandStack[[RLServerAdapter sharedAdapter].commandStack.count-1-indexPath.row];
    
    if(command) {
        // toggle active state
        command.active = !command.active;
        
        // rebuild this row
        [tableView beginUpdates];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView endUpdates];
        
        // active state of a command has changed, state needs to be recomputed
        [[RLServerAdapter sharedAdapter] recomputeCurrentColorState];
    }
    
    // we are done with this row now, as it has it's accessort type updated by now
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UI update

- (void)updateCurrentStateSwatch
{
    // this function may be called from any thread (i.e. a notification), so we need
    // to make sure we run the UI update on the main thread
    dispatch_async(dispatch_get_main_queue(), ^(void){
        currentColorSwatch.backgroundColor = [UIColor colorWithRed:[RLServerAdapter sharedAdapter].currentR/255.0f green:[RLServerAdapter sharedAdapter].currentG/255.0f blue:[RLServerAdapter sharedAdapter].currentB/255.0f alpha:1.0f];
    });
}

@end
