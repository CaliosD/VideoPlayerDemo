//
//  CaptionViewController.m
//  VideoPlayerDemo
//
//  Created by Calios on 7/10/15.
//  Copyright (c) 2015 Calios. All rights reserved.
//

#import "CaptionViewController.h"
#import <PKYStepper.h>

#define CaptionTableViewCellIdentif @"CaptionTableViewCellIdentif"

@interface CaptionViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray     *captionArray;
@property (nonatomic, assign) NSInteger   numberOfRows;

@end

@implementation CaptionViewController

- (id)initWithFrame:(CGRect) frame andCaptionArray:(NSArray *)captions
{
    self = [super init];
    if (self) {
        _captionArray         = captions;
        _numberOfRows = (_captionArray.count > 0) ? _captionArray.count + 2 : 1;
        _selectedRow = 1;
        
        _tableView            = [[UITableView alloc]initWithFrame:frame style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5];
        _tableView.delegate   = self;
        _tableView.dataSource = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:_tableView];
}

#pragma mark - Actions

- (void)captionSwitchValueChanged:(UISwitch *)sender
{
    _isCaptionOpen = sender.on;
    _numberOfRows = _isCaptionOpen ? _captionArray.count + 2 : 1;
    [_tableView reloadData];
    
    self.preferredContentSize = CGSizeMake(280, 44 * _numberOfRows);
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CaptionTableViewCellIdentif];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CaptionTableViewCellIdentif];
    }
    if (cell.contentView.subviews.count > 0) {
        [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    if (indexPath.row == 0) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        UILabel *switchLable = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, 120, 44)];
        switchLable.text = @"caption on/off";
        switchLable.textColor = [UIColor blackColor];
        [cell.contentView addSubview:switchLable];
        
        UISwitch *captionOn = [[UISwitch alloc]initWithFrame:CGRectMake(200, 5, 44, 44)];
        captionOn.on = _isCaptionOpen;
        [captionOn addTarget:self action:@selector(captionSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:captionOn];
    }else if (indexPath.row != _numberOfRows - 1) {
        cell.textLabel.text = [_captionArray objectAtIndex:indexPath.row - 1];
    }else{
        cell.accessoryType = UITableViewCellAccessoryNone;

        PKYStepper *sizeStepper = [[PKYStepper alloc]initWithFrame:CGRectMake(20, 10, 200, 30)];
        sizeStepper.maximum = 2.0;
        sizeStepper.valueChangedCallback = ^(PKYStepper *stepper, float newValue){
            NSString *size;
            switch ((NSInteger)roundf(newValue)) {
                case 0:
                    size = @"小";
                    break;
                case 1:
                    size = @"中";
                    break;
                case 2:
                    size = @"大";
                    break;
                default:
                    break;
            }
            stepper.countLabel.text = size;
//            [[NSNotificationCenter defaultCenter] postNotificationName:CaptionSizeKey object:size];   // Calios: annotated at present.(0710)
        };
        [sizeStepper setup];
        [cell.contentView addSubview:sizeStepper];
    }
    if (indexPath.row == _selectedRow) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (!(indexPath.row == 0 && indexPath.row == _numberOfRows - 1)) {
//        NSIndexPath *index = [NSIndexPath indexPathForRow:_selectedRow inSection:0];
//        UITableViewCell *cell = [tableView cellForRowAtIndexPath:index];
//        cell.accessoryType = UITableViewCellAccessoryNone;
//        
//        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
//        selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
//        
//        [tableView reloadRowsAtIndexPaths:@[index,indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        _selectedRow = indexPath.row + 1;
    }
}

@end
