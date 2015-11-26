//
//  RootViewController.m
//  VideoPlayerDemo
//
//  Created by Calios on 11/20/15.
//  Copyright © 2015 Calios. All rights reserved.
//

#import "RootViewController.h"
#import "ListViewController.h"
#import "SecondListViewController.h"

@interface RootViewController ()

@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) NSArray *clazzArray;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle:@"My Player"];

    _data = @[@"< iOS8",@">= iOS8"];
    _clazzArray = @[NSStringFromClass([ListViewController class]), NSStringFromClass([SecondListViewController class])];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.clearsSelectionOnViewWillAppear = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.textLabel.text = [_data objectAtIndex:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_clazzArray.count > 0) {
        NSString *clazzName = [_clazzArray objectAtIndex:indexPath.row];
        UIViewController *clazz = [[NSClassFromString(clazzName) alloc] init];
        [self.navigationController pushViewController:clazz animated:YES];
    }
    
    
}
@end
